import '../data/telemetry_datasets.dart';
import '../services/earth_data_api.dart';


class DataSection {
  final String id, title, badge;
  final List<String> columns;
  final List<List<String>> rows;
  final String? note;
  const DataSection({
    required this.id,
    required this.title,
    required this.columns,
    required this.rows,
    this.badge = 'reference',
    this.note,
  });

  static const maxRows = 5;
  List<List<String>> get shown => rows.take(maxRows).toList();
  bool get truncated => rows.length > maxRows;
}

String _sg(double v, int d) => (v >= 0 ? '+' : '') + v.toStringAsFixed(d);


const Map<String, double> oceanLandGlobalAnomaly = {'Ocean': 0.02, 'Land': -0.03, 'Global': 0.00};

const List<(String, String, double)> anomalyClasses = [
  ('Very wet', 'above +50%', 50),
  ('Wet', '+10% to +50%', 40),
  ('Normal', '-10% to +10%', 20),
  ('Dry', '-50% to -10%', 40),
  ('Very dry', 'below -50%', 50),
];

const List<(String, String, double)> vegetationCover = [
  ('below 0.1', 'Bare ground, snow, water', 0.1),
  ('0.1 - 0.3', 'Sparse grass or shrub', 0.2),
  ('0.3 - 0.6', 'Crops and moderate cover', 0.3),
  ('above 0.6', 'Dense, healthy forest', 0.4),
];

const List<(String, int, String)> soilMoistureFindings = [
  ('Western Cape, South Africa', 2017, 'Driest since 1981'),
  ('New South Wales, Australia', 2018, 'Worst of 2015-2018'),
  ('California, USA', 2015, 'Below normal, then recovered'),
];

const Map<String, double> annualRainfallMm = {
  'South Africa (national)': 380,
  'New South Wales': 365,
  'Western Cape': 185,
};

const List<(String, int, int, String)> winterWheat2018 = [
  ('Jul', 3, -2, '+5%'),
  ('Sep', -6, -10, 'Same as last year'),
  ('Oct', -13, -10, '18% below 5-yr avg'),
  ('Nov', -18, -12, '21% below 5-yr avg'),
  ('Dec', -20, -18, '17% below 5-yr avg'),
];

const List<(String, double, String)> california2015 = [
  ('Exceptional drought, early April', 44, '44%'),
  ('Exceptional drought, mid May', 47, '47%'),
  ('Water used for irrigation', 41, '41%'),
  ('Wheat yield forecast, Western Cape', -64, '-64% vs 5-yr avg'),
  ('Almond yield, lb/acre (drought vs calm)', 2105, '2,105 vs 2,215'),
];

List<MapEntry<String, double>> vegetationTrendRanking() {
  final r = vegetationIndexByContinent.entries
      .map((e) => MapEntry(e.key, e.value.last - e.value.first))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return r;
}

List<MapEntry<String, double>> temperatureDecadeChange() {
  final names = temperatureAnomalyByDecade.keys.toList();
  final vals = temperatureAnomalyByDecade.values.toList();
  return [for (var i = 1; i < names.length; i++) MapEntry(names[i], vals[i] - vals[i - 1])];
}


DataSection _fallbackNote(DataSection s) => DataSection(
      id: s.id,
      title: s.title,
      columns: s.columns,
      rows: s.rows,
      badge: 'snapshot',
      note: 'Live feed not reachable, showing the reference snapshot.',
    );

List<DataSection> fallbackSections(String slug) {
  switch (slug) {
    case 'precipitation':
      final years = precipitationAnomalyByYear.entries.toList().reversed;
      return [
        DataSection(
          id: 'anomaly-year',
          title: 'Anomaly by year',
          columns: const ['Year', 'mm/day', '% of mean', 'Status'],
          rows: [
            for (final e in years)
              [
                '${e.key}',
                _sg(e.value, 2),
                '${(e.value / globalMeanPrecipitation * 100).toStringAsFixed(1)}%',
                e.value > 0.015 ? 'Wet' : (e.value < -0.015 ? 'Dry' : 'Normal'),
              ],
          ],
          note: 'Latest years first. Long-term mean $globalMeanPrecipitation mm/day.',
        ),
        DataSection(
          id: 'ocean-land-global',
          title: 'Ocean, land and global change',
          columns: const ['Surface', 'Anomaly (mm/day)'],
          rows: [for (final e in oceanLandGlobalAnomaly.entries) [e.key, _sg(e.value, 2)]],
        ),
        DataSection(
          id: 'anomaly-classes',
          title: 'Anomaly classes',
          columns: const ['Class', 'Range'],
          rows: [for (final c in anomalyClasses) [c.$1, c.$2]],
        ),
      ];
    case 'vegetation':
      final rank = vegetationTrendRanking();
      return [
        DataSection(
          id: 'greenness',
          title: 'Greenness index',
          columns: const ['Continent', '2000s', '2010s', '2020s'],
          rows: [
            for (final e in vegetationIndexByContinent.entries)
              [e.key, for (final v in e.value) v.toStringAsFixed(2)],
          ],
        ),
        DataSection(
          id: 'trend-ranking',
          title: 'Trend ranking (2000s to 2020s)',
          columns: const ['#', 'Continent', 'Change'],
          rows: [for (var i = 0; i < rank.length; i++) ['${i + 1}', rank[i].key, _sg(rank[i].value, 2)]],
        ),
        DataSection(
          id: 'index-legend',
          title: 'How to read the index',
          columns: const ['Index', 'Cover'],
          rows: [for (final c in vegetationCover) [c.$1, c.$2]],
        ),
      ];
    case 'temperature':
      final dec = temperatureAnomalyByDecade.entries.toList().reversed.toList();
      final chg = temperatureDecadeChange().reversed.toList();
      final warm = warmestYears.entries.toList();
      final latestYears = (warmestYears.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
      return [
        DataSection(
          id: 'global-temperature',
          title: 'Global temperature',
          columns: const ['Year', 'Anomaly (\u00B0C)'],
          rows: [for (final e in latestYears) ['${e.key}', _sg(e.value, 2)]],
          badge: 'snapshot',
          note: 'Warmest-year snapshot until the live NASA GISTEMP feed answers.',
        ),
        DataSection(
          id: 'surface-temperature',
          title: 'Surface temperature',
          columns: const ['Decade', 'Anomaly (\u00B0C)'],
          rows: [for (final e in dec) [e.key, _sg(e.value, 2)]],
          badge: 'snapshot',
          note: 'Decade snapshot until the live 30-day feed answers.',
        ),
        DataSection(
          id: 'decade-mean',
          title: 'Mean anomaly by decade (\u00B0C)',
          columns: const ['Decade', '\u00B0C'],
          rows: [for (final e in dec) [e.key, _sg(e.value, 2)]],
          note: '*2020s = 2020-2025 only. Base period 1951-1980.',
        ),
        DataSection(
          id: 'decade-change',
          title: 'Change from previous decade',
          columns: const ['Decade', 'Change (\u00B0C)', 'Trend'],
          rows: [for (final e in chg) [e.key, _sg(e.value, 2), e.value >= 0 ? '\u25B2 warmer' : '\u25BC cooler']],
        ),
        DataSection(
          id: 'warmest-years',
          title: 'Ten warmest years',
          columns: const ['Rank', 'Year', 'Anomaly (\u00B0C)'],
          rows: [for (var i = 0; i < warm.length; i++) ['${i + 1}', '${warm[i].key}', _sg(warm[i].value, 2)]],
        ),
      ];
    case 'drought':
      return [
        DataSection(
          id: 'soil-moisture',
          title: 'Soil moisture',
          columns: const ['Region', 'Year', 'Finding'],
          rows: [for (final f in soilMoistureFindings) [f.$1, '${f.$2}', f.$3]],
          badge: 'snapshot',
          note: 'Reference findings until the live soil-moisture feed answers.',
        ),
        DataSection(
          id: 'rainfall',
          title: 'Average annual rainfall (mm)',
          columns: const ['Area', 'Rainfall (mm)'],
          rows: [for (final e in annualRainfallMm.entries) [e.key, e.value.toStringAsFixed(0)]],
          note: 'Western Cape is far below the national average.',
        ),
        DataSection(
          id: 'winter-wheat',
          title: 'Australia 2018 winter wheat',
          columns: const ['Report', 'Crop', 'Area', 'Expected yield'],
          rows: [for (final w in winterWheat2018) [w.$1, '${w.$2 >= 0 ? '+' : ''}${w.$2}%', '${w.$3 >= 0 ? '+' : ''}${w.$3}%', w.$4]],
          note: 'Change vs last year.',
        ),
        DataSection(
          id: 'california-2015',
          title: 'California 2015 and key figures',
          columns: const ['Measure', 'Value'],
          rows: [for (final c in california2015) [c.$1, c.$3]],
        ),
      ];
  }
  return const [];
}

Future<List<DataSection>> loadSections(String slug) async {
  final base = fallbackSections(slug);
  final api = EarthDataApi();

  Future<DataSection> live(String id, Future<LiveTable> Function() load) async {
    final fb = base.firstWhere((s) => s.id == id);
    try {
      final t = await load().timeout(const Duration(seconds: 25));
      if (t.rows.isEmpty) return fb;
      return DataSection(
        id: id,
        title: fb.title,
        columns: t.headers,
        rows: t.rows,
        badge: 'live',
        note: 'Data: ${t.asOf}. Source: ${t.source}.',
      );
    } catch (_) {
      return _fallbackNote(fb);
    }
  }

  final out = <String, Future<DataSection>>{};
  if (slug == 'temperature') {
    out['global-temperature'] =
        live('global-temperature', () async => EarthDataApi.temperatureYears(await api.fetchGlobalTemperature(), count: 5));
    out['surface-temperature'] =
        live('surface-temperature', () async => EarthDataApi.temperatureWindows(await api.fetchWindows(continentPoints)));
  } else if (slug == 'drought') {
    out['soil-moisture'] =
        live('soil-moisture', () async => EarthDataApi.soilMoisture(await api.fetchSoilMoisture(droughtPoints)));
  }
  final resolved = {for (final e in out.entries) e.key: await e.value};
  return [for (final s in base) resolved[s.id] ?? s];
}
