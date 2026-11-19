import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.hideOnError = false,
  });

  final String title;
  final Color color;
  final String? note;
  final List<double>? flex;

  final bool hideOnError;
  final Future<LiveTable> Function() load;

  @override
  State<LiveTableCard> createState() => _LiveTableCardState();
}

class _LiveTableCardState extends State<LiveTableCard> {
  late Future<LiveTable> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LiveTable>(
      future: _future,
      builder: (context, snap) {
        final done = snap.connectionState == ConnectionState.done;
        final failed = done && (snap.hasError || snap.data == null);
        if (widget.hideOnError && !(done && !failed)) return const SizedBox.shrink();
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
                  ? _errorBody(snap.error)
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

  Widget _tableBody(BuildContext context, LiveTable t) {
    return Column(children: [
      gridTable(
        headers: t.headers,
        headerColor: Color.lerp(widget.color, Colors.black, 0.35)!,
        flex: widget.flex,
        rows: [
          for (final r in t.rows) [for (var i = 0; i < r.length; i++) cell(r[i], bold: i == 0, left: i == 0)],
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Data: ${t.asOf}. Source: ${t.source}.',
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

class LiveCards {
  LiveCards._();
  static final EarthDataApi _api = EarthDataApi();

  static Widget globalTemperatureYears(Color c) => LiveTableCard(
        title: 'Live: global temperature, latest years',
        color: c,
        flex: const [1.2, 1.4, 1.4],
        load: () async => EarthDataApi.temperatureYears(await _api.fetchGlobalTemperature()),
      );

  static Widget globalTemperatureDecades(Color c) => LiveTableCard(
        title: 'Live: decade means (computed from annual NASA GISTEMP)',
        color: c,
        flex: const [1, 1.2, 1.2, 0.8],
        load: () async => EarthDataApi.temperatureDecades(await _api.fetchGlobalTemperature()),
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
      );

  static Widget vegetationNdvi(Color c) => LiveTableCard(
        title: 'Live: NDVI vegetation index (NASA MODIS/Terra)',
        color: c,
        hideOnError: true, 
        note: 'NDVI runs from about 0 (bare ground) to 1 (dense vegetation). Sample locations, one pixel each.',
        flex: const [2, 1.3, 0.8, 1.3, 1, 0.9],
        load: () async => EarthDataApi.ndvi(await _api.fetchNdvi(continentPoints)),
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
      );
}
