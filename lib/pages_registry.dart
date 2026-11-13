import 'package:flutter/material.dart';
import 'data/ecosystems.dart';
import 'models/ecosystem.dart';
import 'pages/about_contact_pages.dart';
import 'pages/admin_pdf_pages.dart';
import 'pages/charts_page.dart';
import 'main.dart' show EcosystemHomeScreen;
import 'pages/home_page.dart';
import 'screens/home_screen.dart';
import 'pages/media_pages.dart';
import 'pages/notes_page.dart';
import 'pages/scenes_pages.dart';
import 'pages/services_agenda_pages.dart';

const baseUrl = 'https://animation-panoramas-website.onrender.com';

class PageInfo {
  final String slug, title, description;
  final Widget Function() build;
  const PageInfo(this.slug, this.title, this.description, this.build);
  String get url => '$baseUrl/$slug';
}

/// Single source of truth: drawer, PDFs, RSS and the sitemap all read this.
final List<PageInfo> appPages = [
  PageInfo('home', 'Home', 'Overview of every page and scene.', () => const HomeScreen()),
  PageInfo('main', 'Main', 'Panorama viewer with live telemetry.', () => const EcosystemHomeScreen()),
  PageInfo('metrics', 'Metrics', 'Open-Meteo, Grafana MCP and telemetry widgets.', () => const HomePage()),
  PageInfo('scenes', 'Scenes', 'Responsive grid of all seven scenes.', () => const ScenesPage()),
  PageInfo('pictures', 'Pictures', 'Vertical carousel of sprite sheets with zoom.', () => const PicturesPage()),
  PageInfo('videos', 'Videos', 'Seven scene videos, autoplay and muted.', () => const VideosPage()),
  PageInfo('videos-vimeo', 'Videos Vimeo', 'Seven Vimeo players.', () => const VimeoPage()),
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

/// sitemap.xml content (copy to web/sitemap.xml at build time).
String sitemapXml() {
  final urls = [
    ...appPages.map((p) => p.url),
    ...getEcosystems().map((e) => '$baseUrl/scene/${e.slug}'),
  ];
  return '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
      '${urls.map((u) => '  <url><loc>$u</loc></url>').join('\n')}\n</urlset>';
}
