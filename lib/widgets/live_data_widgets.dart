import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/telemetry_datasets.dart';
import '../data/telemetry_sections.dart' show soilMoistureFindings;
import '../services/earth_data_api.dart';
import 'structured_table.dart';

class LiveTableCard extends StatefulWidget {
  const LiveTableCard({
    super.key,
    required this.title,
    required this.color,
    required this.load,
    this.note,
    this.flex,
    this.fallback,
  });

  final String title;
  final Color color;
  final String? note;
  final List<double>? flex;
  final LiveTable Function()? fallback;
  final Future<LiveTable> Function() load;

  @override
  State<LiveTableCard> createState() => _LiveTableCardState();
}

class _LiveTableCardState extends State<LiveTableCard> {
  late Future<LiveTable> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<LiveTable> _fetch() => widget.load().timeout(const Duration(seconds: 30));

  void _retry() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LiveTable>(
      future: _future,
      builder: (context, snap) {
        final done = snap.connectionState == ConnectionState.done;
        final failed = done && (snap.hasError || snap.data == null);
        final snapshot = failed ? widget.fallback?.call() : null;
        return TableCard(
          title: widget.title,
          color: widget.color,
          note: widget.note,
          child: !done
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Fetching live data\u2026', style: TextStyle(color: Colors.black54)),
                  ]),
                )
              : failed
                  ? (snapshot != null
                      ? Column(children: [
                          _snapshotBanner(snap.error),
                          _tableBody(context, snapshot, snapshot: true),
                        ])
                      : _errorBody(snap.error))
                  : _tableBody(context, snap.data!),
        );
      },
    );
  }

  Widget _errorBody(Object? error) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        const Text(
          'Live data could not be loaded. The reference tables further down this page are unaffected.',
          style: TextStyle(color: Colors.black87),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Cause: ${EarthDataApi.describeError(error)}',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ),
        TextButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    );
  }

  Widget _snapshotBanner(Object? error) {
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(children: [
        const Icon(Icons.cloud_off, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Live feed not reachable (${error == null ? 'unknown' : EarthDataApi.describeError(error)}). '
            'Showing the reference snapshot.',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        TextButton(onPressed: _retry, child: const Text('Retry')),
      ]),
    );
  }

  Widget _tableBody(BuildContext context, LiveTable t, {bool snapshot = false}) {
    return Column(children: [
      gridTable(
        headers: t.headers,
        headerColor: Color.lerp(widget.color, Colors.black, 0.35)!,
        flex: (widget.flex != null && widget.flex!.length == t.headers.length) ? widget.flex : null,
        rows: [
          for (final r in t.rows) [for (var i = 0; i < r.length; i++) cell(r[i], bold: i == 0, left: i == 0)],
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('${snapshot ? 'Snapshot' : 'Data'}: ${t.asOf}. Source: ${t.source}.',
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy CSV'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: t.toCsv()));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied')));
          },
        ),
      ),
    ]);
  }
}

String _sg(double v, int d) => (v >= 0 ? '+' : '') + v.toStringAsFixed(d);

class LiveCards {
  LiveCards._();
  static final EarthDataApi _api = EarthDataApi();

  static Widget globalTemperatureYears(Color c) => LiveTableCard(
        title: 'Live: global temperature, latest years',
        color: c,
        flex: const [1.2, 1.4, 1.4],
        load: () async => EarthDataApi.temperatureYears(await _api.fetchGlobalTemperature()),
        fallback: () => LiveTable(
          headers: const ['Year', 'Anomaly (\u00B0C vs 1951-1980)'],
          rows: [
            for (final e in (warmestYears.entries.toList()..sort((a, b) => b.key.compareTo(a.key))))
              ['${e.key}', _sg(e.value, 2)],
          ],
          source: 'NASA GISS reference snapshot (warmest years)',
          asOf: 'static',
        ),
      );

  static Widget globalTemperatureDecades(Color c) => LiveTableCard(
        title: 'Live: decade means (computed from annual NASA GISTEMP)',
        color: c,
        flex: const [1, 1.2, 1.2, 0.8],
        load: () async => EarthDataApi.temperatureDecades(await _api.fetchGlobalTemperature()),
        fallback: () => LiveTable(
          headers: const ['Decade', 'Mean anomaly (\u00B0C)'],
          rows: [for (final e in temperatureAnomalyByDecade.entries.toList().reversed) [e.key, _sg(e.value, 2)]],
          source: 'NASA GISS reference snapshot',
          asOf: 'static; *2020s = 2020-2025 only',
        ),
      );

  static Widget temperatureNow(Color c) => LiveTableCard(
        title: 'Live: surface temperature, last 30 days vs 5-year baseline',
        color: c,
        note: 'Sample locations (one per continent), not continental averages.',
        flex: const [2, 1.2, 1.2, 1.1],
        load: () async => EarthDataApi.temperatureWindows(await _api.fetchWindows(continentPoints)),
      );

  static Widget precipitationNow(Color c) => LiveTableCard(
        title: 'Live: precipitation, last 30 days vs 5-year baseline',
        color: c,
        note: 'Sample locations (one per continent), not continental averages.',
        flex: const [2, 1.2, 1.2, 1],
        load: () async => EarthDataApi.precipitationWindows(await _api.fetchWindows(continentPoints)),
        fallback: () => LiveTable(
          headers: const ['Year', 'Anomaly (mm/day)', '% of mean'],
          rows: [
            for (final e in precipitationAnomalyByYear.entries.toList().reversed)
              ['${e.key}', _sg(e.value, 2), '${(e.value / globalMeanPrecipitation * 100).toStringAsFixed(1)}%'],
          ],
          source: 'NASA GPCP reference snapshot',
          asOf: 'static; long-term mean $globalMeanPrecipitation mm/day',
        ),
      );

  static Widget vegetationNdvi(Color c) => LiveTableCard(
        title: 'Live: NDVI vegetation index (NASA MODIS/Terra)',
        color: c,
        note: 'NDVI runs from about 0 (bare ground) to 1 (dense vegetation). Sample locations, one pixel each.',
        flex: const [2, 1.3, 0.8, 1.3, 1, 0.9],
        load: () async => EarthDataApi.ndvi(await _api.fetchNdvi(continentPoints)),
        fallback: () => LiveTable(
          headers: const ['Continent', '2000s', '2010s', '2020s'],
          rows: [
            for (final e in vegetationIndexByContinent.entries) [e.key, for (final v in e.value) v.toStringAsFixed(2)],
          ],
          source: 'NASA MODIS reference snapshot (greenness index)',
          asOf: 'static',
        ),
      );

  static Widget vegetationWaterSupply(Color c) => LiveTableCard(
        title: 'Live: soil water available to vegetation, last 30 days vs 5-year baseline',
        color: c,
        note: 'An indicator of vegetation water supply, not a vegetation index. Sample locations, one per continent.',
        flex: const [2.2, 1.2, 0.9, 1.2, 0.9, 1.4],
        load: () async => EarthDataApi.soilMoisture(await _api.fetchSoilMoisture(continentPoints)),
      );

  static Widget vegetationWaterDemand(Color c) => LiveTableCard(
        title: 'Live: vegetation water demand (ET0), last 30 days vs 5-year baseline',
        color: c,
        flex: const [2, 1.2, 1.2, 1],
        load: () async => EarthDataApi.evapotranspirationWindows(await _api.fetchWindows(continentPoints)),
      );

  static Widget droughtSoilMoisture(Color c) => LiveTableCard(
        title: 'Live: soil moisture, last 30 days vs 5-year baseline',
        color: c,
        flex: const [2.2, 1.2, 0.9, 1.2, 0.9, 1.4],
        load: () async => EarthDataApi.soilMoisture(await _api.fetchSoilMoisture(droughtPoints)),
        fallback: () => LiveTable(
          headers: const ['Region', 'Year', 'Finding'],
          rows: [for (final f in soilMoistureFindings) [f.$1, '${f.$2}', f.$3]],
          source: 'NASA reference findings',
          asOf: 'static',
        ),
      );
}