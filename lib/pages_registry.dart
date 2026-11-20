import 'package:flutter/material.dart';
import 'data/ecosystems.dart';
import 'models/ecosystem.dart';
import 'pages/about_company.dart';
import 'pages/pdf_library.dart';
import 'pages/charts.dart';
import 'main.dart' show EcosystemHomeScreen;
import 'pages/home.dart';
import 'screens/home_screen.dart';
import 'pages/media.dart';
import 'pages/notes.dart';
import 'pages/scenes.dart';
import 'pages/earth_science.dart';
import 'pages/precipitation.dart';
import 'pages/temperature.dart';
import 'pages/vegetation.dart';
import 'pages/drought.dart';
import 'pages/services_agenda.dart';

const baseUrl = 'https://animation-panoramas-website.onrender.com';

class PageInfo {
  final String slug, title, description;
  final Widget Function() build;

  final String group;
  const PageInfo(this.slug, this.title, this.description, this.build, {this.group = 'site'});

  String get url => slug == 'main' ? baseUrl : '$baseUrl/$slug';

  String get path => slug == 'main' ? '/' : '/$slug';

  double get priority => (slug == 'main' || slug == 'home') ? 1.0 : (group == 'climate' || slug == 'earth-science' ? 0.8 : 0.7);
}

final List<PageInfo> appPages = [
  PageInfo('home', 'Home', 'Overview of every page and scene.', () => const HomeScreen()),
  PageInfo('main', 'Main', 'Panorama viewer with live telemetry.', () => const EcosystemHomeScreen()),
  PageInfo('metrics', 'Metrics', 'Open-Meteo, Grafana MCP and telemetry widgets.', () => const HomePage()),
  PageInfo('scenes', 'Scenes', 'Responsive grid of all seven scenes.', () => const ScenesPage()),
  PageInfo('pictures', 'Pictures', 'Vertical carousel of sprite sheets with zoom.', () => const PicturesPage()),
  PageInfo('videos', 'Videos', 'Seven scene videos, autoplay and muted.', () => const VideosPage()),
  PageInfo('videos-vimeo', 'Videos Vimeo', 'Seven Vimeo players.', () => const VimeoPage()),
  PageInfo('earth-science', 'Earth Science', 'NASA satellite analytics: precipitation, temperature, vegetation and drought.', () => const EarthSciencePage(), group: 'climate'),
  PageInfo('precipitation', 'Precipitation', 'Global precipitation anomaly by year.', () => const PrecipitationPage(), group: 'climate'),
  PageInfo('temperature', 'Temperature', 'Global temperature anomaly by decade.', () => const TemperaturePage(), group: 'climate'),
  PageInfo('vegetation', 'Vegetation', 'Vegetation index trend by continent.', () => const VegetationPage(), group: 'climate'),
  PageInfo('drought', 'Drought', 'Soil moisture anomaly by region.', () => const DroughtPage(), group: 'climate'),
  PageInfo('about', 'About', 'Animated service hours and app counters.', () => const AboutPage()),
  PageInfo('contact', 'Contact', 'Contact details, share buttons, RSS.', () => const ContactPage()),
  PageInfo('app-dev-services', 'App Dev Services', 'React Native, Android, iOS, SwiftUI, Flutter, .NET.', () => const ServicesPage()),
  PageInfo('coding-agenda', 'Coding Agenda', 'Book a date, time and service.', () => const AgendaPage()),
  PageInfo('notes', 'Notes', 'Notes stored in SQLite.', () => const NotesPage()),
  PageInfo('chart', 'Chart', 'Ten charts built from your bookings.', () => const ChartsPage()),
  PageInfo('pdf-library', 'PDF Library', 'One PDF per page.', () => const PdfLibraryPage()),
  PageInfo('admin', 'Admin', 'Admin login and panel.', () => const AdminLoginPage()),
];

PageInfo pageBySlug(String s) => appPages.firstWhere((p) => p.slug == s);

void openPage(BuildContext c, String slug) =>
    Navigator.of(c, rootNavigator: true).pushNamed('/$slug'); // real URL: /<slug>

void openScene(BuildContext c, Ecosystem e) =>
    Navigator.of(c, rootNavigator: true).pushNamed('/scene/${e.slug}');

String sitemapXml() {
  final entries = <(String, double)>[
    for (final p in appPages) (p.url, p.priority),
    for (final e in getEcosystems()) ('$baseUrl/scene/${e.slug}', 0.6),
  ];
  final body = entries
      .map((e) => '  <url>\n    <loc>${e.$1}</loc>\n    <changefreq>weekly</changefreq>\n    <priority>${e.$2.toStringAsFixed(1)}</priority>\n  </url>')
      .join('\n');
  return '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n$body\n</urlset>\n';
}
