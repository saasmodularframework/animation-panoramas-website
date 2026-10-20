import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/ecosystem.dart';
import 'data/ecosystems.dart';
import 'services/olap_service.dart';
import 'widgets/grafana_mcp_dashboard_widget.dart';
import 'widgets/telemetry_observability_widget.dart';
import 'widgets/ecosystem_sprite_loader.dart';
import 'widgets/open_meteo_live_widget.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() {
  runApp(const EcosystemApp());
}

class EcosystemApp extends StatelessWidget {
  const EcosystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ecosystem Viewer',
      home: const EcosystemHomeScreen(),
    );
  }
}

class EcosystemHomeScreen extends StatefulWidget {
  const EcosystemHomeScreen({super.key});

  @override
  State<EcosystemHomeScreen> createState() => _EcosystemHomeScreenState();
}

class _EcosystemHomeScreenState extends State<EcosystemHomeScreen> {
  int _currentIndex = 0;
  bool _isFetchingLive = false;
  
  Map<String, dynamic> _telemetryData = {
    'temperature_2m': 21.0,
    'apparent_temperature': 22.0,
    'relative_humidity_2m': 55.0,
    'precipitation': 0.0,
    'cloud_cover': 15.0,
    'surface_pressure': 1012.0,
    'wind_speed_10m': 8.5,
    'wind_direction_10m': 140.0,
    'wind_gusts_10m': 15.0,
    'weather_code': 0,
    'sunrise': '06:00:00 AM',
    'sunset': '06:00:00 PM',
    'specimen': 'Scanning...',
    'status': 'SYNCING',
  };

  List<Map<String, dynamic>> _clickHouseLogs = [];
  final OlapApiService _olapApiService = OlapApiService();

  @override
  void initState() {
    super.initState();
    _loadParallelTelemetry();
  }

  Future<void> _loadParallelTelemetry() async {
    setState(() => _isFetchingLive = true);
    final ecosystem = ecosystems[_currentIndex];

    final data = await _olapApiService.fetchEcosystemWithParallelAI(
      ecosystem.slug,
      ecosystem.lat,
      ecosystem.lng,
    );

    final analyticsData = await _olapApiService.queryClickHouseAnalytics(ecosystem.slug);

    setState(() {
      _telemetryData = data;
      _clickHouseLogs = analyticsData;
      _isFetchingLive = false;
    });
  }

  void _onSegmentSelected(Set<int> newSelection) {
    setState(() {
      _currentIndex = newSelection.first;
    });
    _loadParallelTelemetry();
  }

  String _toRoman(int number) {
    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const numerals = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    var num = number;
    var result = '';
    for (int i = 0; i < values.length; i++) {
      while (num >= values[i]) {
        result += numerals[i];
        num -= values[i];
      }
    }
    return result.isEmpty ? number.toString() : result;
  }

  @override
  Widget build(BuildContext context) {
    final ecosystem = ecosystems[_currentIndex];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ecosystem.background.top,
          brightness: Brightness.dark,
        ),
      ),
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          body: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ecosystem.background.top, ecosystem.background.bottom],
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: EcosystemSpriteLoader(
                    key: ValueKey(ecosystem.spritePath),
                    imagePath: ecosystem.spritePath,
                    totalFrames: ecosystem.spriteTotalFrames,
                    columns: ecosystem.spriteColumns,
                    rows: ecosystem.spriteRows,
                  ),
                ),
              ),
              Positioned.fill(
                child: ModelViewer(
                  key: ValueKey(ecosystem.slug),
                  src: ecosystem.modelPath,
                  alt: ecosystem.title,
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: Colors.transparent,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Card.outlined(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      FaIcon(FontAwesomeIcons.globe, size: 12, color: colorScheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        "LAT: ${ecosystem.lat}, LNG: ${ecosystem.lng}",
                                        style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Card.filled(
                                color: colorScheme.secondaryContainer.withOpacity(0.6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      FaIcon(FontAwesomeIcons.leaf, size: 12, color: colorScheme.onSecondaryContainer),
                                      const SizedBox(width: 6),
                                      Text(
                                        ecosystem.type == "3d" ? "3D SCENE" : "2D SCENE",
                                        style: textTheme.labelMedium?.copyWith(letterSpacing: 0.8, color: colorScheme.onSecondaryContainer),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ecosystem.title,
                            style: textTheme.displayLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ecosystem.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.85), height: 1.3),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              OpenMeteoLiveWidget(
                                weatherData: _telemetryData,
                                isFetching: _isFetchingLive,
                                onRefresh: _loadParallelTelemetry,
                              ),
                              const SizedBox(height: 10),
                              GrafanaMcpDashboardWidget(
                                telemetry: _telemetryData,
                                isFetching: _isFetchingLive,
                                onRefresh: _loadParallelTelemetry,
                              ),
                              const SizedBox(height: 10),
                              TelemetryObservabilityWidget(
                                clickHouseLogs: _clickHouseLogs,
                                ecosystemData: _telemetryData,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  setState(() {
                                    _currentIndex = (_currentIndex - 1 + ecosystems.length) % ecosystems.length;
                                  });
                                  _loadParallelTelemetry();
                                },
                                icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 12),
                                label: const Text("Prev"),
                              ),
                              const SizedBox(width: 12),
                              SegmentedButton<int>(
                                segments: List.generate(
                                  ecosystems.length,
                                  (index) => ButtonSegment<int>(
                                    value: index,
                                    label: Text(_toRoman(index + 1)),
                                  ),
                                ),
                                selected: {_currentIndex},
                                onSelectionChanged: _onSegmentSelected,
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _currentIndex = (_currentIndex + 1) % ecosystems.length;
                                  });
                                  _loadParallelTelemetry();
                                },
                                icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 12),
                                label: const Text("Next"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
