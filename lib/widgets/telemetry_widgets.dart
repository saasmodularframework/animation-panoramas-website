import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/telemetry_datasets.dart';
import '../data/ecosystems.dart';
import '../pages_registry.dart';
import '../services/telemetry_api.dart';
import 'structured_table.dart';

const climateSlugs = ['precipitation', 'temperature', 'vegetation', 'drought'];

class ClimateNavBar extends StatelessWidget {
  const ClimateNavBar({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final index = climateSlugs.indexOf(current);
    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) {
        if (climateSlugs[i] == current) return;
        Navigator.of(context, rootNavigator: true).pushReplacementNamed('/${climateSlugs[i]}');
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'Precipitation'),
        NavigationDestination(
            icon: Icon(Icons.thermostat_outlined), selectedIcon: Icon(Icons.thermostat), label: 'Temperature'),
        NavigationDestination(icon: Icon(Icons.eco_outlined), selectedIcon: Icon(Icons.eco), label: 'Vegetation'),
        NavigationDestination(
            icon: Icon(Icons.landscape_outlined), selectedIcon: Icon(Icons.landscape), label: 'Drought'),
      ],
    );
  }
}

class SourceCard extends StatelessWidget {
  const SourceCard({super.key, required this.dataset, required this.color});
  final TelemetryDataset dataset;
  final Color color;

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return TableCard(
      title: 'About this dataset',
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Variable: ${dataset.variable}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(dataset.summary, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 10),
          const Text('Features', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
          for (final f in dataset.features)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('\u2022  ', style: TextStyle(color: Colors.black87)),
                Expanded(child: Text(f, style: const TextStyle(color: Colors.black87))),
              ]),
            ),
          const SizedBox(height: 10),
          const Text('Data sources', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
          for (final s in dataset.sources)
            InkWell(
              onTap: () => _open(s.url),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(Icons.open_in_new, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.note.isEmpty ? s.name : '${s.name} \u2013 ${s.note}',
                      style: TextStyle(color: color, decoration: TextDecoration.underline),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class DatasetTableCard extends StatelessWidget {
  const DatasetTableCard({super.key, required this.dataset, required this.color, this.title});
  final TelemetryDataset dataset;
  final Color color;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return TableCard(
      title: title ?? 'Raw dataset (${dataset.unit})',
      color: color,
      child: Column(children: [
        gridTable(
          headers: dataset.columns,
          headerColor: Color.lerp(color, Colors.black, 0.35)!,
          rows: [
            for (final r in dataset.rows)
              [for (var i = 0; i < r.length; i++) cell('${r[i]}', bold: i == 0, left: i == 0 && r[i] is String)],
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy CSV'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: dataset.toCsv()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied')));
            },
          ),
        ),
      ]),
    );
  }
}

enum LiveMetric { precipitation, temperature, soilMoisture, evapotranspiration }

/// Seven-day live telemetry table from Open-Meteo for the first scene's coordinates.
class LiveTelemetryCard extends StatefulWidget {
  const LiveTelemetryCard({super.key, required this.metric, required this.color});
  final LiveMetric metric;
  final Color color;

  @override
  State<LiveTelemetryCard> createState() => _LiveTelemetryCardState();
}

class _Spec {
  final String title, unit, note;
  final double? Function(DailyReading) pick;
  final double max;
  const _Spec(this.title, this.unit, this.note, this.pick, this.max);
}

class _LiveTelemetryCardState extends State<LiveTelemetryCard> {
  late Future<List<DailyReading>> _future;
  final _api = TelemetryApiService();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DailyReading>> _load() {
    final eco = getEcosystems().first;
    return _api.fetchDailySeries(lat: eco.lat, lng: eco.lng, days: 7);
  }

  _Spec get _spec {
    switch (widget.metric) {
      case LiveMetric.precipitation:
        return _Spec('Live precipitation, last 7 days', 'mm', 'Daily precipitation sum.',
            (DailyReading r) => r.precipitationSum, 20);
      case LiveMetric.temperature:
        return _Spec('Live temperature, last 7 days', '\u00B0C', 'Daily mean at 2 m.',
            (DailyReading r) => r.temperatureMean, 40);
      case LiveMetric.soilMoisture:
        return _Spec('Live soil moisture, last 7 days', 'm\u00B3/m\u00B3', 'Daily mean of the 0-7 cm layer.',
            (DailyReading r) => r.soilMoisture, 0.5);
      case LiveMetric.evapotranspiration:
        return _Spec('Live evapotranspiration, last 7 days', 'mm',
            'FAO-56 reference ET0, a proxy for vegetation water demand (not NDVI).',
            (DailyReading r) => r.evapotranspiration, 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final eco = getEcosystems().first;
    return TableCard(
      title: spec.title,
      color: widget.color,
      note: '${spec.note} Open-Meteo, ${eco.title} (${eco.lat}, ${eco.lng}).',
      child: FutureBuilder<List<DailyReading>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator());
          }
          if (snap.hasError || (snap.data?.isEmpty ?? true)) {
            return Column(children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Live feed unavailable. The NASA tables on this page are unaffected.',
                    style: TextStyle(color: Colors.black87)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => setState(() => _future = _load()),
              ),
            ]);
          }
          final rows = snap.data!;
          return gridTable(
            headers: ['Date', spec.unit],
            headerColor: Color.lerp(widget.color, Colors.black, 0.35)!,
            flex: const [1, 2],
            rows: [
              for (final r in rows)
                [
                  cell(r.isoDate, bold: true),
                  () {
                    final v = spec.pick(r);
                    return v == null
                        ? cell('n/a')
                        : barCell(v, spec.max, widget.color, v.toStringAsFixed(2));
                  }(),
                ],
            ],
          );
        },
      ),
    );
  }
}

class ClimateHubCard extends StatelessWidget {
  const ClimateHubCard({super.key, required this.slug, required this.icon, required this.color, required this.dataset});
  final String slug;
  final IconData icon;
  final Color color;
  final TelemetryDataset dataset;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPage(context, slug),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Text(dataset.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              const Icon(Icons.chevron_right),
            ]),
            const SizedBox(height: 8),
            Text(dataset.variable, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(dataset.summary),
          ]),
        ),
      ),
    );
  }
}
