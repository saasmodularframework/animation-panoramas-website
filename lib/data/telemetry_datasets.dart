
class DatasetSource {
  final String name, url, note;
  const DatasetSource(this.name, this.url, [this.note = '']);
}

class TelemetryDataset {
  final String id, title, variable, unit, summary;
  final List<String> features;
  final List<DatasetSource> sources;
  final List<String> columns;
  final List<List<Object>> rows;

  const TelemetryDataset({
    required this.id,
    required this.title,
    required this.variable,
    required this.unit,
    required this.summary,
    required this.features,
    required this.sources,
    required this.columns,
    required this.rows,
  });

  List<Map<String, Object>> toRecords() => [
        for (final r in rows)
          {for (var i = 0; i < columns.length; i++) columns[i]: r[i]},
      ];

  String toCsv() {
    String esc(Object v) {
      final s = '$v';
      return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    return [
      columns.map(esc).join(','),
      for (final r in rows) r.map(esc).join(','),
    ].join('\n');
  }
}


const double globalMeanPrecipitation = 2.69;

const Map<int, double> precipitationAnomalyByYear = {
  2015: 0.03, 2016: 0.04, 2017: 0.01, 2018: -0.01, 2019: 0.02, 2020: 0.03,
  2021: -0.02, 2022: -0.03, 2023: 0.00, 2024: 0.02, 2025: -0.02,
};

final TelemetryDataset precipitationDataset = TelemetryDataset(
  id: 'precipitation',
  title: 'Precipitation',
  variable: 'Global precipitation anomaly by year',
  unit: 'mm/day',
  summary: 'Visualizes global-average monthly precipitation over land and ocean, '
      'tracking long-term anomalies.',
  features: const [
    'Global-average monthly precipitation over land and ocean',
    'Long-term anomaly tracking against the multi-year mean',
    'Cross-checked with GPM IMERG, including TRMM-era records back to 1998',
  ],
  sources: const [
    DatasetSource('NASA Goddard GPCP (Global Precipitation Climatology Project)',
        'https://disc.gsfc.nasa.gov/', 'Monthly and daily versions'),
    DatasetSource('NASA Goddard Precipitation Research',
        'https://earth.gsfc.nasa.gov/meso/research/precipitation', 'Research insights'),
    DatasetSource('GPM IMERG Data Directory', 'https://gpm.nasa.gov/node/3037',
        'Cross-check, historical TRMM-era records back to 1998'),
  ],
  columns: const ['Year', 'Anomaly (mm/day)', '% of mean'],
  rows: [
    for (final e in precipitationAnomalyByYear.entries)
      [e.key, e.value, (e.value / globalMeanPrecipitation * 100).toStringAsFixed(1)],
  ],
);


const Map<String, double> temperatureAnomalyByDecade = {
  '1880s': -0.212, '1890s': -0.237, '1900s': -0.313, '1910s': -0.327,
  '1920s': -0.236, '1930s': -0.122, '1940s': 0.043, '1950s': -0.048,
  '1960s': -0.030, '1970s': 0.034, '1980s': 0.247, '1990s': 0.385,
  '2000s': 0.589, '2010s': 0.804, '2020s*': 1.063,
};


const Map<int, double> warmestYears = {
  2024: 1.2817, 2025: 1.185, 2023: 1.1675, 2016: 1.01, 2020: 1.005,
  2019: 0.9775, 2017: 0.9125, 2015: 0.895, 2022: 0.89, 2018: 0.8483,
};

final TelemetryDataset temperatureDataset = TelemetryDataset(
  id: 'temperature',
  title: 'Temperature',
  variable: 'Global temperature anomaly by decade',
  unit: '\u00B0C',
  summary: 'Structured breakdown of decadal temperature deviations across Northern '
      'and Southern hemispheres relative to historical baselines.',
  features: const [
    'Decadal anomalies from the 1880s to the 2020s',
    'Change from the previous decade',
    'Ten warmest years on record',
  ],
  sources: const [
    DatasetSource('DataHub Core Global Temperature / NASA GISS Report',
        'https://datahub.io/core/global-temp/UPDATE_SCRIPT_MAINTENANCE_REPORT'),
  ],
  columns: const ['Decade', 'Anomaly (\u00B0C)'],
  rows: [
    for (final e in temperatureAnomalyByDecade.entries) [e.key, e.value],
  ],
);


const Map<String, List<double>> vegetationIndexByContinent = {
  'Africa': [0.42, 0.43, 0.43],
  'Asia': [0.38, 0.40, 0.41],
  'Europe': [0.45, 0.46, 0.47],
  'North America': [0.40, 0.41, 0.42],
  'South America': [0.60, 0.60, 0.59],
  'Oceania': [0.30, 0.31, 0.31],
};

final TelemetryDataset vegetationDataset = TelemetryDataset(
  id: 'vegetation',
  title: 'Vegetation',
  variable: 'Vegetation index trend by continent',
  unit: 'index (0-1)',
  summary: 'Evaluates canopy health, vegetative growth trends, and rainfall '
      'response indexes worldwide.',
  features: const [
    'Greenness index by continent and decade',
    'Trend ranking from the 2000s to the 2020s',
    'Index legend from bare ground to dense forest',
  ],
  sources: const [
    DatasetSource('NASA Earth Observatory (Terra satellite)',
        'https://earthobservatory.nasa.gov/global-maps/MOD_NDVI_M/GPM_3IMERGM',
        'Vegetation index measured via Terra'),
    DatasetSource('Sentinel Hub Space Apps Data Offer',
        'https://www.sentinel-hub.com/spaceapps-data/'),
    DatasetSource('Space Apps 2020 Resources Page',
        'https://2020.spaceappschallenge.org/challenges/observe/scanning-lifeforms/resources',
        'NASA GIBS, Worldview and Earthdata Search'),
  ],
  columns: const ['Continent', '2000s', '2010s', '2020s'],
  rows: [
    for (final e in vegetationIndexByContinent.entries) [e.key, ...e.value],
  ],
);


final TelemetryDataset droughtDataset = TelemetryDataset(
  id: 'drought',
  title: 'Drought',
  variable: 'Soil moisture anomaly by region',
  unit: 'soil moisture anomaly',
  summary: 'Monitors surface layer and root zone soil moisture content, categorizing '
      'regional drought severity and risk levels.',
  features: const [
    'Surface layer and root zone soil moisture',
    'Regional drought severity and risk levels',
    'High-resolution radiometer and radar metrics (SMAP)',
  ],
  sources: const [
    DatasetSource('NASA SMAP (Soil Moisture Active Passive) Research Article, PMC7931972',
        'https://pmc.ncbi.nlm.nih.gov/articles/PMC7931972/',
        'High-resolution radiometer and radar metrics'),
  ],
  columns: const ['Region', 'Year', 'Finding'],
  rows: const [
    ['Western Cape, South Africa', 2017, 'Driest since 1981'],
    ['New South Wales, Australia', 2018, 'Worst of 2015-2018'],
    ['California, USA', 2015, 'Below normal, then recovered'],
  ],
);

final List<TelemetryDataset> telemetryDatasets = [
  precipitationDataset,
  temperatureDataset,
  vegetationDataset,
  droughtDataset,
];
