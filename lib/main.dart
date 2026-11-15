import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:navbar_router/navbar_router.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi, sqfliteFfiInit;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app_state.dart';
import 'data/ecosystems.dart';
import 'l10n/app_strings.dart';
import 'pages/about_contact_pages.dart';
import 'pages/media_pages.dart';
import 'pages/scenes_pages.dart';
import 'pages_registry.dart';
import 'services/olap_service.dart';
import 'widgets/ecosystem_sprite_loader.dart';
import 'widgets/grafana_mcp_dashboard_widget.dart';
import 'widgets/open_meteo_live_widget.dart';
import 'widgets/page_shell.dart';
import 'widgets/telemetry_observability_widget.dart';
import 'widgets/textured_button.dart';

class SeoConfig {
  final String baseUrl, siteName, description;
  const SeoConfig({required this.baseUrl, required this.siteName, required this.description});
}

class RouteMeta {
  final String path, title, description;
  const RouteMeta({required this.path, required this.title, required this.description});
}

class AppRoute {
  final RouteMeta meta;
  final WidgetBuilder builder;
  const AppRoute(this.meta, this.builder);
}

const seo = SeoConfig(
  baseUrl: baseUrl, // https://animation-panoramas-website.onrender.com (defined in pages_registry.dart)
  siteName: 'Animation Panoramas',
  description: 'Interactive ecosystem panoramas, videos, services and agenda.',
);

const primaryColor = Color(0xFF1B5C2A); // '#1B5C2A'

const _pages = {
  'main': 'Panorama viewer with live telemetry.',
  'home': 'Overview of every page and scene.',
  'metrics': 'Open-Meteo, Grafana MCP and telemetry widgets.',
  'scenes': 'Responsive grid of all seven scenes.',
  'pictures': 'Vertical carousel of sprite sheets with zoom.',
  'videos': 'Seven scene videos.',
  'videos-vimeo': 'Seven Vimeo players.',
  'about': 'Service hours and app counters.',
  'contact': 'Contact details and RSS.',
  'app-dev-services': 'React Native, Android, iOS, SwiftUI, Flutter, .NET.',
  'coding-agenda': 'Book a date, time and service.',
  'notes': 'Notes.',
  'chart': 'Charts.',
  'pdf-library': 'PDF per page.',
  'admin': 'Admin.',
};

final routes = <AppRoute>[
  for (final e in _pages.entries)
    AppRoute(
      RouteMeta(path: e.key == 'main' ? '/' : '/${e.key}', title: pageBySlug(e.key).title, description: e.value),
      (ctx) => e.key == 'main' ? const RootNav() : pageBySlug(e.key).build(),
    ),
];

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  final path = Uri.parse(settings.name ?? '/').path;
  String title = seo.siteName;
  WidgetBuilder? builder;

  for (final r in routes) {
    if (r.meta.path == path) {
      title = r.meta.title;
      builder = r.builder;
    }
  }
  if (builder == null && path.startsWith('/scene/')) {
    final slug = path.substring('/scene/'.length);
    for (final e in getEcosystems()) {
      if (e.slug == slug) {
        title = e.title;
        builder = (_) => SceneDetailPage(ecosystem: e);
      }
    }
  }
  builder ??= (_) => const NotFoundPage();
  final b = builder;
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (c) => Title(title: title == seo.siteName ? title : '$title · ${seo.siteName}', color: primaryColor, child: b(c)),
  );
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(seo.siteName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('404 – page not found'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false), child: Text(context.tr('home'))),
          ]),
        ),
      );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); 
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb; 
  } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await initializeDateFormatting();
  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('de', timeago.DeMessages());
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  timeago.setLocaleMessages('hi', timeago.HiMessages());
  runApp(const EcosystemApp());
}

class EcosystemApp extends StatelessWidget {
  const EcosystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppState.locale,
      builder: (_, locale, __) => ValueListenableBuilder<ThemeMode>(
        valueListenable: AppState.themeMode,
        builder: (_, mode, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: seo.siteName,
          locale: locale,
          supportedLocales: AppStrings.supported,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: mode,
          theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: primaryColor)),
          darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark)),
          initialRoute: '/',
          onGenerateRoute: _onGenerateRoute,
          onGenerateInitialRoutes: (name) => [_onGenerateRoute(RouteSettings(name: name))],
        ),
      ),
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
    'status': 'ONLINE_SYNCHRONIZED',
  };

  final OlapApiService _olapApiService = OlapApiService();

  @override
  void initState() {
    super.initState();
    _loadParallelTelemetry();
  }

  Future<void> _loadParallelTelemetry() async {
    setState(() => _isFetchingLive = true);
    final ecosystem = getEcosystems()[_currentIndex];
    final data = await _olapApiService.fetchEcosystemWithParallelAI(ecosystem.slug, ecosystem.lat, ecosystem.lng);
    if (!mounted) return;
    setState(() {
      _telemetryData = data;
      _isFetchingLive = false;
    });
  }

  void _select(int i) {
    setState(() => _currentIndex = i);
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
    final ecosystems = getEcosystems();
    final ecosystem = ecosystems[_currentIndex];
    final cs = Theme.of(context).colorScheme;

    return PageShell(
      slug: 'main',
      title: context.tr('appTitle'),
      ecosystem: ecosystem,
      child: Stack(fit: StackFit.expand, children: [
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
        Opacity(
          opacity: 0.4,
          child: EcosystemSpriteLoader(
            key: ValueKey(ecosystem.spritePath),
            imagePath: ecosystem.spritePath,
            totalFrames: ecosystem.spriteTotalFrames,
            columns: ecosystem.spriteColumns,
            rows: ecosystem.spriteRows,
          ),
        ),
        ModelViewer(
          key: ValueKey(ecosystem.slug),
          src: ecosystem.modelPath,
          alt: ecosystem.title,
          autoRotate: true,
          cameraControls: true,
          backgroundColor: Colors.transparent,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card.filled(
              color: cs.secondaryContainer.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  FaIcon(FontAwesomeIcons.leaf, size: 12, color: cs.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text(ecosystem.type == '3d' ? context.tr('scene3d') : context.tr('scene2d'),
                      style: TextStyle(letterSpacing: 0.8, color: cs.onSecondaryContainer, fontSize: 11)),
                ]),
              ),
            ),

            Row(children: [
              Flexible(
                child: AutoSizeText(ecosystem.title,
                    maxLines: 1,
                    minFontSize: 16,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 12),
              TexturedButton(label: context.tr('more'), icon: Icons.arrow_forward, compact: true, onPressed: () => openScene(context, ecosystem)),
            ]),
            const SizedBox(height: 4),
            Text(context.sceneDesc(ecosystem.slug), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, height: 1.3)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [
                  OpenMeteoLiveWidget(weatherData: _telemetryData, isFetching: _isFetchingLive, onRefresh: _loadParallelTelemetry),
                  const SizedBox(height: 10),
                  GrafanaMcpDashboardWidget(telemetry: _telemetryData, isFetching: _isFetchingLive, onRefresh: _loadParallelTelemetry),
                  const SizedBox(height: 10),
                  TelemetryObservabilityWidget(clickHouseLogs: const [], ecosystemData: _telemetryData),
                ]),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                FilledButton.tonalIcon(
                  onPressed: () => _select((_currentIndex - 1 + ecosystems.length) % ecosystems.length),
                  icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 12),
                  label: Text(context.tr('prev')),
                ),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: List.generate(ecosystems.length, (i) => ButtonSegment<int>(value: i, label: Text(_toRoman(i + 1)))),
                  selected: {_currentIndex},
                  onSelectionChanged: (s) => _select(s.first),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _select((_currentIndex + 1) % ecosystems.length),
                  icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 12),
                  label: Text(context.tr('next')),
                ),
                const SizedBox(width: 90), 
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class RootNav extends StatelessWidget {
  const RootNav({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      NavbarItem(Icons.home_outlined, context.tr('home'), selectedIcon: const Icon(Icons.home, size: 26)),
      NavbarItem(Icons.grid_view_outlined, context.tr('scenes'), selectedIcon: const Icon(Icons.grid_view, size: 26)),
      NavbarItem(Icons.photo_library_outlined, context.tr('pictures'), selectedIcon: const Icon(Icons.photo_library, size: 26)),
      NavbarItem(Icons.contact_mail_outlined, context.tr('contact'), selectedIcon: const Icon(Icons.contact_mail, size: 26)),
    ];
    final roots = <Widget>[const EcosystemHomeScreen(), const ScenesPage(), const PicturesPage(), const ContactPage()];
    return NavbarRouter(
      errorBuilder: (_) => const Center(child: Text('Error 404')),
      onBackButtonPressed: (isExiting) => isExiting,
      destinationAnimationCurve: Curves.fastOutSlowIn,
      destinationAnimationDuration: 400,
      type: NavbarType.notched,
      destinations: [
        for (int i = 0; i < items.length; i++)
          DestinationRouter(
            navbarItem: items[i],
            destinations: [Destination(route: '/', widget: roots[i])],
            initialRoute: '/',
          ),
      ],
    );
  }
}