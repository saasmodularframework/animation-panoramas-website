import 'dart:async';

import 'package:dio/dio.dart';

class SamplePoint {
  final String name;
  final double lat, lng;
  const SamplePoint(this.name, this.lat, this.lng);
}

const continentPoints = [
  SamplePoint('Africa (Nairobi)', -1.29, 36.82),
  SamplePoint('Asia (Delhi)', 28.61, 77.21),
  SamplePoint('Europe (Kyiv)', 50.45, 30.52),
  SamplePoint('North America (Kansas City)', 39.10, -94.58),
  SamplePoint('South America (Manaus)', -3.12, -60.02),
  SamplePoint('Oceania (Sydney)', -33.87, 151.21),
];

const droughtPoints = [
  SamplePoint('Western Cape, South Africa (Cape Town)', -33.92, 18.42),
  SamplePoint('New South Wales, Australia (Dubbo)', -32.25, 148.60),
  SamplePoint('California, USA (Fresno)', 36.74, -119.79),
];

class LiveTable {
  final List<String> headers;
  final List<List<String>> rows;
  final String source;
  final String asOf;
  const LiveTable({required this.headers, required this.rows, required this.source, required this.asOf});

  String toCsv() {
    String esc(String s) => s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    return [headers.map(esc).join(','), for (final r in rows) r.map(esc).join(',')].join('\n');
  }
}

class AnnualAnomaly {
  final int year;
  final double? gistemp, gcag;
  const AnnualAnomaly(this.year, this.gistemp, this.gcag);
}

class WindowStat {
  final String name;
  final double? recent, baseline;
  final bool isSum; 
  const WindowStat(this.name, this.recent, this.baseline, this.isSum);


  double? get delta {
    final r = recent, b = baseline;
    if (r == null || b == null) return null;
    if (isSum) return b.abs() < 0.05 ? null : (r / b - 1) * 100;
    return r - b;
  }
}

class WindowSet {
  final DateTime windowEnd;
  final int days;
  final Map<String, List<WindowStat>> byVariable;
  const WindowSet(this.windowEnd, this.days, this.byVariable);
}

class SoilStat {
  final String name;
  final double? surface, surfaceBase, root, rootBase;
  const SoilStat(this.name, this.surface, this.surfaceBase, this.root, this.rootBase);
  double? _pct(double? a, double? b) => (a == null || b == null || b.abs() < 1e-6) ? null : (a / b - 1) * 100;
  double? get surfacePct => _pct(surface, surfaceBase);
  double? get rootPct => _pct(root, rootBase);
}

class NdviStat {
  final String name;
  final String? latestDate, yearAgoDate;
  final double? latest, yearAgo;
  const NdviStat(this.name, this.latestDate, this.latest, this.yearAgoDate, this.yearAgo);
}

class EarthDataApi {
  EarthDataApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 40),
            ));

  final Dio _dio;
  static final Map<String, Future<dynamic>> _cache = {};

  static const archiveEndpoint = 'https://archive-api.open-meteo.com/v1/archive';
  static const annualCsvUrls = [
    'https://raw.githubusercontent.com/datasets/global-temp/main/data/annual.csv',
    'https://datahub.io/core/global-temp/_r/-/data/annual.csv',
  ];
  static const ornlBase = 'https://modis.ornl.gov/rst/api/v1';


  static const windowDays = 30;
  static const lagDays = 7;
  static const baselineYears = 5;

  Future<T> _cached<T>(String key, Future<T> Function() load) {
    final hit = _cache[key];
    if (hit != null) return hit as Future<T>;
    final f = load();
    _cache[key] = f;

    f.then((_) {}, onError: (_) => _cache.remove(key));
    return f;
  }

  static DateTime defaultWindowEnd() {
    final n = DateTime.now().toUtc();
    return DateTime.utc(n.year, n.month, n.day).subtract(const Duration(days: lagDays));
  }


  Future<List<AnnualAnomaly>> fetchGlobalTemperature() => _cached('gtemp', () async {
        Object? last;
        for (final url in annualCsvUrls) {
          try {
            final r = await _dio.get<String>(url, options: Options(responseType: ResponseType.plain));
            final rows = parseAnnualCsv(r.data ?? '');
            if (rows.isNotEmpty) return rows;
          } catch (e) {
            last = e;
          }
        }
        throw last ?? StateError('Global temperature source not reachable');
      });

  static List<AnnualAnomaly> parseAnnualCsv(String csv) {
    final byYear = <int, List<double?>>{};
    for (final line in csv.split('\n').skip(1)) {
      final p = line.trim().split(',');
      if (p.length < 3) continue;
      final year = int.tryParse(p[1]);
      final v = double.tryParse(p[2]);
      if (year == null || v == null) continue;
      final e = byYear.putIfAbsent(year, () => <double?>[null, null]);
      if (p[0] == 'GISTEMP') {
        e[0] = v;
      } else if (p[0] == 'GCAG') {
        e[1] = v;
      }
    }
    final years = byYear.keys.toList()..sort();
    return [for (final y in years) AnnualAnomaly(y, byYear[y]![0], byYear[y]![1])];
  }

  Future<WindowSet> fetchWindows(List<SamplePoint> points) =>
      _cached('win_${points.map((p) => p.name).join('|')}', () async {
        final end = defaultWindowEnd();
        final start = end.subtract(const Duration(days: windowDays - 1));

        final perYear = await Future.wait([
          for (var y = 0; y <= baselineYears; y++)
            _archive(points,
                start: _ymd(DateTime.utc(start.year - y, start.month, start.day)),
                end: _ymd(DateTime.utc(end.year - y, end.month, end.day)),
                daily: 'precipitation_sum,temperature_2m_mean,et0_fao_evapotranspiration'),
        ]);
        return computeWindows(points, mergeYears(points.length, perYear), end, windowDays);
      });

  static List<dynamic> mergeYears(int pointCount, List<List<dynamic>> perYear) {
    return [
      for (var i = 0; i < pointCount; i++)
        {
          'daily': () {
            final m = <String, List<dynamic>>{};
            for (final resp in perYear) {
              if (i >= resp.length) continue;
              final daily = ((resp[i] as Map)['daily'] as Map?) ?? const {};
              for (final e in daily.entries) {
                (m[e.key as String] ??= <dynamic>[]).addAll((e.value as List?) ?? const []);
              }
            }
            return m;
          }(),
        },
    ];
  }

  static WindowSet computeWindows(List<SamplePoint> points, List<dynamic> responses, DateTime end, int days) {
    const vars = {
      'precipitation_sum': true,
      'temperature_2m_mean': false,
      'et0_fao_evapotranspiration': true,
    };
    final out = <String, List<WindowStat>>{for (final v in vars.keys) v: []};
    for (var i = 0; i < points.length && i < responses.length; i++) {
      final daily = ((responses[i] as Map)['daily'] as Map?) ?? const {};
      final times = ((daily['time'] as List?) ?? const []).cast<String>();
      for (final e in vars.entries) {
        final values = (daily[e.key] as List?) ?? const [];
        final byDate = <String, double>{};
        for (var k = 0; k < times.length && k < values.length; k++) {
          final v = values[k];
          if (v is num) byDate[times[k]] = v.toDouble();
        }
        final recent = _windowValue(byDate, end, days, 0, e.value);
        final base = <double>[];
        for (var y = 1; y <= baselineYears; y++) {
          final v = _windowValue(byDate, end, days, y, e.value);
          if (v != null) base.add(v);
        }
        final baseline = base.length >= 3 ? base.reduce((a, b) => a + b) / base.length : null;
        out[e.key]!.add(WindowStat(points[i].name, recent, baseline, e.value));
      }
    }
    return WindowSet(end, days, out);
  }

  static double? _windowValue(Map<String, double> byDate, DateTime end, int days, int yearsBack, bool sum) {
    final vals = <double>[];
    for (var d = 0; d < days; d++) {
      final day = end.subtract(Duration(days: d));
      final shifted = DateTime.utc(day.year - yearsBack, day.month, day.day);
      final v = byDate[_ymd(shifted)];
      if (v != null) vals.add(v);
    }
    if (vals.length < days * 0.8) return null; // too many gaps to trust
    final total = vals.reduce((a, b) => a + b);
    return sum ? total * days / vals.length : total / vals.length;
  }

  Future<List<SoilStat>> fetchSoilMoisture(List<SamplePoint> points) =>
      _cached('soil_${points.map((p) => p.name).join('|')}', () async {
        final end = defaultWindowEnd();
        final start = end.subtract(const Duration(days: windowDays - 1));
        // One request per year: the current window plus the same window 1..5 years back.
        final perYear = await Future.wait([
          for (var y = 0; y <= baselineYears; y++)
            _archive(points,
                start: _ymd(DateTime.utc(start.year - y, start.month, start.day)),
                end: _ymd(DateTime.utc(end.year - y, end.month, end.day)),
                hourly: 'soil_moisture_0_to_7cm,soil_moisture_28_to_100cm'),
        ]);
        return computeSoil(points, perYear);
      });

  static List<SoilStat> computeSoil(List<SamplePoint> points, List<List<dynamic>> perYear) {
    double? mean(Map hourly, String key) {
      final l = ((hourly[key] as List?) ?? const []).whereType<num>().toList();
      if (l.length < 24 * 20) return null;
      return l.reduce((a, b) => a + b) / l.length;
    }

    Map hourlyOf(List<dynamic> resp, int i) =>
        i < resp.length ? ((((resp[i] as Map)['hourly']) as Map?) ?? const {}) : const {};

    double? baseMean(int i, String key) {
      final v = <double>[];
      for (var y = 1; y < perYear.length; y++) {
        final m = mean(hourlyOf(perYear[y], i), key);
        if (m != null) v.add(m);
      }
      return v.length >= 3 ? v.reduce((a, b) => a + b) / v.length : null;
    }

    return [
      for (var i = 0; i < points.length; i++)
        SoilStat(
          points[i].name,
          mean(hourlyOf(perYear[0], i), 'soil_moisture_0_to_7cm'),
          baseMean(i, 'soil_moisture_0_to_7cm'),
          mean(hourlyOf(perYear[0], i), 'soil_moisture_28_to_100cm'),
          baseMean(i, 'soil_moisture_28_to_100cm'),
        ),
    ];
  }

  static Future<void> _queueTail = Future<void>.value();

  static Future<T> _serial<T>(Future<T> Function() job) {
    final done = Completer<T>();
    _queueTail = _queueTail.then((_) async {
      try {
        done.complete(await job());
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }

  Future<List<dynamic>> _archive(List<SamplePoint> pts,
      {required String start, required String end, String? daily, String? hourly}) {
    return _serial(() async {
      for (var attempt = 0;; attempt++) {
        try {
          final r = await _dio.get(archiveEndpoint, queryParameters: {
            'latitude': pts.map((p) => p.lat).join(','),
            'longitude': pts.map((p) => p.lng).join(','),
            'start_date': start,
            'end_date': end,
            if (daily != null) 'daily': daily,
            if (hourly != null) 'hourly': hourly,
            'timezone': 'UTC',
          });
          await Future<void>.delayed(const Duration(milliseconds: 150));
          final d = r.data;
          return d is List ? d : <dynamic>[d];
        } on DioException catch (e) {
          if (e.response?.statusCode == 429 && attempt < 3) {
            await Future<void>.delayed(Duration(milliseconds: 1500 * (attempt + 1)));
            continue;
          }
          rethrow;
        }
      }
    });
  }

  Future<List<NdviStat>> fetchNdvi(List<SamplePoint> points) =>
      _cached('ndvi_${points.map((p) => p.name).join('|')}', () async {
        final stats = await Future.wait(points.map(_ndviFor));
        if (stats.every((s) => s.latest == null)) {
          throw StateError('NASA ORNL MODIS service returned no NDVI values');
        }
        return stats;
      });

  Future<NdviStat> _ndviFor(SamplePoint p) async {
    try {
      final opts = Options(headers: {'Accept': 'application/json'});
      final q = {'latitude': p.lat, 'longitude': p.lng};
      final d = await _dio.get('$ornlBase/MOD13Q1/dates', queryParameters: q, options: opts);
      final dates = parseOrnlDates(d.data);
      if (dates.isEmpty) return NdviStat(p.name, null, null, null, null);
      final latest = dates.last;
      final target = DateTime.parse(latest.value).subtract(const Duration(days: 365));
      final yearAgo = dates.reduce((a, b) =>
          DateTime.parse(a.value).difference(target).abs() <= DateTime.parse(b.value).difference(target).abs() ? a : b);

      Future<double?> ndvi(String modisDate) async {
        final r = await _dio.get('$ornlBase/MOD13Q1/subset',
            queryParameters: {
              ...q,
              'band': '250m_16_days_NDVI',
              'startDate': modisDate,
              'endDate': modisDate,
              'kmAboveBelow': 0,
              'kmLeftRight': 0,
            },
            options: opts);
        return parseOrnlNdvi(r.data);
      }

      final results = await Future.wait([ndvi(latest.key), ndvi(yearAgo.key)]);
      return NdviStat(p.name, latest.value, results[0], yearAgo.value, results[1]);
    } catch (_) {
      return NdviStat(p.name, null, null, null, null);
    }
  }

  static List<MapEntry<String, String>> parseOrnlDates(dynamic json) {
    final list = json is Map ? (json['dates'] as List? ?? const []) : (json is List ? json : const []);
    return [
      for (final e in list)
        if (e is Map && e['modis_date'] != null && e['calendar_date'] != null)
          MapEntry('${e['modis_date']}', '${e['calendar_date']}'),
    ];
  }

  static double? parseOrnlNdvi(dynamic json) {
    if (json is! Map) return null;
    final subset = json['subset'] as List?;
    if (subset == null || subset.isEmpty) return null;
    final data = ((subset.first as Map)['data'] as List? ?? const []).whereType<num>().where((v) => v != -3000).toList();
    if (data.isEmpty) return null;
    final scale = double.tryParse('${(json['header'] as Map?)?['scale'] ?? ''}') ?? 0.0001;
    return data.reduce((a, b) => a + b) / data.length * scale;
  }

  static String describeError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final reason = data is Map && data['reason'] != null ? '${data['reason']}' : null;
      if (code != null) return 'HTTP $code${reason != null ? ': $reason' : ''} from ${e.requestOptions.uri.host}';
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        return 'request blocked or no network to ${e.requestOptions.uri.host} (usually CORS; see the browser console)';
      }
      return '${e.type.name} calling ${e.requestOptions.uri.host}';
    }
    final t = '$e';
    return t.length > 200 ? '${t.substring(0, 200)}...' : t;
  }


  static String _ymd(DateTime d) => d.toIso8601String().substring(0, 10);
  static String _sign(double v, int digits) => (v >= 0 ? '+' : '') + v.toStringAsFixed(digits);
  static String _f(double? v, int digits) => v == null ? 'n/a' : v.toStringAsFixed(digits);

  static LiveTable temperatureYears(List<AnnualAnomaly> a, {int count = 12}) {
    final recent = a.reversed.take(count).toList();
    final nowYear = DateTime.now().year;
    return LiveTable(
      headers: const ['Year', 'NASA GISTEMP (\u00B0C vs 1951-1980)', 'HadCRUT5 (\u00B0C vs 20th century)'],
      rows: [
        for (final r in recent)
          [
            r.year == nowYear ? '${r.year} (year to date)' : '${r.year}',
            _f(r.gistemp, 2),
            _f(r.gcag, 2),
          ],
      ],
      source: 'NASA GISTEMP and Met Office HadCRUT5 via DataHub core/global-temp',
      asOf: 'through ${a.last.year}',
    );
  }

  static LiveTable temperatureDecades(List<AnnualAnomaly> a) {
    final g = a.where((e) => e.gistemp != null).toList();
    final byDecade = <int, List<double>>{};
    for (final e in g) {
      byDecade.putIfAbsent(e.year ~/ 10 * 10, () => <double>[]).add(e.gistemp!);
    }
    final decades = byDecade.keys.toList()..sort();
    final rows = <List<String>>[];
    double? prev;
    for (final d in decades) {
      final v = byDecade[d]!;
      final mean = v.reduce((x, y) => x + y) / v.length;
      final partial = v.length < 10;
      rows.add([
        '${d}s${partial ? '*' : ''}',
        mean.toStringAsFixed(2),
        prev == null ? '-' : _sign(mean - prev, 2),
        '${v.length}',
      ]);
      prev = mean;
    }
    return LiveTable(
      headers: const ['Decade', 'Mean anomaly (\u00B0C)', 'Change vs previous', 'Years'],
      rows: rows.reversed.toList(),
      source: 'NASA GISTEMP via DataHub core/global-temp (computed here from annual values)',
      asOf: 'through ${g.last.year}; * incomplete decade',
    );
  }

  static String _window(WindowSet w) {
    final start = w.windowEnd.subtract(Duration(days: w.days - 1));
    return '${_ymd(start)} to ${_ymd(w.windowEnd)}';
  }

  static const _openMeteoSource = 'Open-Meteo archive (ERA5 reanalysis)';

  static LiveTable precipitationWindows(WindowSet w) => LiveTable(
        headers: const ['Location', 'Last 30 days (mm)', '5-year baseline (mm)', 'Change'],
        rows: [
          for (final s in w.byVariable['precipitation_sum']!)
            [s.name, _f(s.recent, 0), _f(s.baseline, 0), s.delta == null ? 'n/a' : '${_sign(s.delta!, 0)}%'],
        ],
        source: _openMeteoSource,
        asOf: _window(w),
      );

  static LiveTable temperatureWindows(WindowSet w) => LiveTable(
        headers: const ['Location', 'Last 30 days (\u00B0C)', '5-year baseline (\u00B0C)', 'Anomaly (\u00B0C)'],
        rows: [
          for (final s in w.byVariable['temperature_2m_mean']!)
            [s.name, _f(s.recent, 1), _f(s.baseline, 1), s.delta == null ? 'n/a' : _sign(s.delta!, 1)],
        ],
        source: _openMeteoSource,
        asOf: _window(w),
      );

  static LiveTable evapotranspirationWindows(WindowSet w) => LiveTable(
        headers: const ['Location', 'Last 30 days (mm)', '5-year baseline (mm)', 'Change'],
        rows: [
          for (final s in w.byVariable['et0_fao_evapotranspiration']!)
            [s.name, _f(s.recent, 0), _f(s.baseline, 0), s.delta == null ? 'n/a' : '${_sign(s.delta!, 0)}%'],
        ],
        source: '$_openMeteoSource, FAO-56 reference evapotranspiration (vegetation water demand)',
        asOf: _window(w),
      );

  static String _soilStatus(SoilStat s) {
    final p = [s.surfacePct, s.rootPct].whereType<double>().toList();
    if (p.isEmpty) return 'n/a';
    final avg = p.reduce((a, b) => a + b) / p.length;
    if (avg <= -10) return 'Drier than baseline';
    if (avg >= 10) return 'Wetter than baseline';
    return 'Near baseline';
  }

  static LiveTable soilMoisture(List<SoilStat> stats) {
    final end = defaultWindowEnd();
    final start = end.subtract(const Duration(days: windowDays - 1));
    return LiveTable(
      headers: const ['Region', 'Surface 0-7 cm (m\u00B3/m\u00B3)', 'vs baseline', 'Root zone 28-100 cm', 'vs baseline', 'Status'],
      rows: [
        for (final s in stats)
          [
            s.name,
            _f(s.surface, 3),
            s.surfacePct == null ? 'n/a' : '${_sign(s.surfacePct!, 0)}%',
            _f(s.root, 3),
            s.rootPct == null ? 'n/a' : '${_sign(s.rootPct!, 0)}%',
            _soilStatus(s),
          ],
      ],
      source: 'Open-Meteo archive (ERA5-Land soil moisture); baseline = same 30 days, previous 5 years. '
          'Status is a simple +/-10% comparison, not an official drought class.',
      asOf: '${_ymd(start)} to ${_ymd(end)}',
    );
  }

  static LiveTable ndvi(List<NdviStat> stats) {
    final dates = stats.map((s) => s.latestDate).whereType<String>().toList()..sort();
    return LiveTable(
      headers: const ['Location', 'Latest composite', 'NDVI', 'Same time last year', 'NDVI last year', 'Change'],
      rows: [
        for (final s in stats)
          [
            s.name,
            s.latestDate ?? 'n/a',
            _f(s.latest, 2),
            s.yearAgoDate ?? 'n/a',
            _f(s.yearAgo, 2),
            (s.latest == null || s.yearAgo == null) ? 'n/a' : _sign(s.latest! - s.yearAgo!, 2),
          ],
      ],
      source: 'NASA MODIS/Terra MOD13Q1 250 m 16-day NDVI via ORNL DAAC web service',
      asOf: dates.isEmpty ? 'no data' : 'latest composite ${dates.last}',
    );
  }
}

