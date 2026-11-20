import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../data/ecosystems.dart';
import '../l10n/app_strings.dart';
import '../pages_registry.dart';
import '../services/olap_service.dart';
import '../widgets/ecosystem_sprite_loader.dart';
import '../widgets/grafana_mcp_dashboard_widget.dart';
import '../widgets/open_meteo_live_widget.dart';
import '../widgets/page_shell.dart';
import '../widgets/telemetry_observability_widget.dart';
import '../widgets/textured_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _i = 0;
  bool _fetching = false;
  final _olap = OlapApiService();
  Map<String, dynamic> _t = {
    'temperature_2m': 21.0, 'apparent_temperature': 22.0, 'relative_humidity_2m': 55.0, 'precipitation': 0.0,
    'cloud_cover': 15.0, 'surface_pressure': 1012.0, 'wind_speed_10m': 8.5, 'wind_direction_10m': 140.0,
    'wind_gusts_10m': 15.0, 'weather_code': 0, 'sunrise': '06:00:00 AM', 'sunset': '06:00:00 PM',
    'specimen': 'Scanning...', 'status': 'ONLINE_SYNCHRONIZED',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _fetching = true);
    final e = getEcosystems()[_i];
    final data = await _olap.fetchEcosystemWithParallelAI(e.slug, e.lat, e.lng);
    if (!mounted) return;
    setState(() {
      _t = data;
      _fetching = false;
    });
  }

  void _go(int i) {
    setState(() => _i = i);
    _load();
  }

  String _roman(int n) {
    const v = [10, 9, 5, 4, 1];
    const s = ['X', 'IX', 'V', 'IV', 'I'];
    var r = '';
    for (var k = 0; k < v.length; k++) {
      while (n >= v[k]) {
        r += s[k];
        n -= v[k];
      }
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final list = getEcosystems();
    final e = list[_i];
    return PageShell(
      slug: 'main',
      title: 'Ecosystem Viewer',
      ecosystem: e,
      child: Stack(fit: StackFit.expand, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [e.background.top, e.background.bottom])),
        ),
        Opacity(
          opacity: 0.4,
          child: EcosystemSpriteLoader(
              key: ValueKey(e.spritePath), imagePath: e.spritePath, totalFrames: e.spriteTotalFrames, columns: e.spriteColumns, rows: e.spriteRows),
        ),
        ModelViewer(key: ValueKey(e.slug), src: e.modelPath, alt: e.title, autoRotate: true, cameraControls: true, backgroundColor: Colors.transparent),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Chip(
                avatar: const FaIcon(FontAwesomeIcons.leaf, size: 12),
                label: Text(e.type == '3d' ? context.tr('scene3d') : context.tr('scene2d'), style: const TextStyle(fontSize: 11)),
              ),
            ]),

            Row(children: [
              Flexible(
                child: AutoSizeText(e.title, maxLines: 1, minFontSize: 16,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              TexturedButton(label: context.tr('more'), icon: Icons.arrow_forward, compact: true, onPressed: () => openScene(context, e)),
            ]),
            const SizedBox(height: 4),
            Text(e.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.3)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [
                  OpenMeteoLiveWidget(weatherData: _t, isFetching: _fetching, onRefresh: _load),
                  const SizedBox(height: 10),
                  GrafanaMcpDashboardWidget(telemetry: _t, isFetching: _fetching, onRefresh: _load),
                  const SizedBox(height: 10),
                  TelemetryObservabilityWidget(clickHouseLogs: const [], ecosystemData: _t),
                ]),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                FilledButton.tonalIcon(
                    onPressed: () => _go((_i - 1 + list.length) % list.length),
                    icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 12),
                    label: Text(context.tr('prev'))),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: [for (int k = 0; k < list.length; k++) ButtonSegment(value: k, label: Text(_roman(k + 1)))],
                  selected: {_i},
                  onSelectionChanged: (s) => _go(s.first),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                    onPressed: () => _go((_i + 1) % list.length),
                    icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 12),
                    label: Text(context.tr('next'))),
                const SizedBox(width: 90),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
