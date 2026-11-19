import 'package:dio/dio.dart';

class DailyReading {
  final DateTime date;
  final double? temperatureMean; 
  final double? precipitationSum; 
  final double? soilMoisture; 
  final double? evapotranspiration; 

  const DailyReading({
    required this.date,
    this.temperatureMean,
    this.precipitationSum,
    this.soilMoisture,
    this.evapotranspiration,
  });

  String get isoDate => date.toIso8601String().substring(0, 10);

  Map<String, Object?> toJson() => {
        'date': isoDate,
        'temperature_2m_mean': temperatureMean,
        'precipitation_sum': precipitationSum,
        'soil_moisture_0_to_7cm': soilMoisture,
        'et0_fao_evapotranspiration': evapotranspiration,
      };
}

class TelemetryApiService {
  TelemetryApiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static final Map<String, List<DailyReading>> _cache = {};

  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  Future<List<DailyReading>> fetchDailySeries({
    required double lat,
    required double lng,
    int days = 7,
  }) async {
    final key = '${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_$days';
    final hit = _cache[key];
    if (hit != null) return hit;

    final response = await _dio.get(_endpoint, queryParameters: {
      'latitude': lat,
      'longitude': lng,
      'daily': 'temperature_2m_mean,precipitation_sum,et0_fao_evapotranspiration',
      'hourly': 'soil_moisture_0_to_7cm',
      'past_days': days,
      'forecast_days': 1,
      'timezone': 'auto',
    });

    final series = parseDailySeries(response.data as Map);
    _cache[key] = series;
    return series;
  }

  static List<DailyReading> parseDailySeries(Map json) {
    final daily = (json['daily'] as Map?) ?? const {};
    final hourly = (json['hourly'] as Map?) ?? const {};

    double? num0(List? l, int i) =>
        (l != null && i < l.length) ? (l[i] as num?)?.toDouble() : null;

    final sums = <String, double>{};
    final counts = <String, int>{};
    final hTimes = (hourly['time'] as List?) ?? const [];
    final hSoil = hourly['soil_moisture_0_to_7cm'] as List?;
    for (var i = 0; i < hTimes.length; i++) {
      final v = num0(hSoil, i);
      if (v == null) continue;
      final day = (hTimes[i] as String).substring(0, 10);
      sums[day] = (sums[day] ?? 0) + v;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final times = (daily['time'] as List?) ?? const [];
    final temp = daily['temperature_2m_mean'] as List?;
    final rain = daily['precipitation_sum'] as List?;
    final et0 = daily['et0_fao_evapotranspiration'] as List?;

    return [
      for (var i = 0; i < times.length; i++)
        DailyReading(
          date: DateTime.parse(times[i] as String),
          temperatureMean: num0(temp, i),
          precipitationSum: num0(rain, i),
          evapotranspiration: num0(et0, i),
          soilMoisture: counts[times[i]] == null
              ? null
              : sums[times[i]]! / counts[times[i]]!,
        ),
    ];
  }

  static String toCsv(List<DailyReading> rows) {
    String f(double? v) => v == null ? '' : v.toStringAsFixed(3);
    return [
      'date,temperature_2m_mean,precipitation_sum,soil_moisture_0_to_7cm,et0_fao_evapotranspiration',
      for (final r in rows)
        '${r.isoDate},${f(r.temperatureMean)},${f(r.precipitationSum)},${f(r.soilMoisture)},${f(r.evapotranspiration)}',
    ].join('\n');
  }
}
