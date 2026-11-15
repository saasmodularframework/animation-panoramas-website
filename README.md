# Ecosystem Viewer & OLAP Telemetry Platform (Flutter Web)

An advanced, responsive 3D and 2D ecosystem and panorama explorer built with Flutter Web, featuring containerized real-time telemetry pipelines. This application allows users to seamlessly navigate through global biomes, render interactive 3D `.glb` models, run transparent sprite-sheet animations, and monitor real-time AI-augmented ecological metrics via Parallel.ai, Open-Meteo, ClickHouse OLAP, and Grafana MCP.

## Key Features

- **3D & 2D Biome Navigation**: Switch dynamically between global environments like Jungle Forests, Ocean Floors, Cloud Forests, and Seagrass Meadows. Every scene has its own page, opened with the textured "More" button next to the scene name.
- **Multi-Page Application**: Home overview, Main scene viewer, Metrics, Scenes (responsive grid), Pictures, Videos, Videos Vimeo, About, Contact, App Dev Services, Coding Agenda, Notes, Chart, PDF Library and Admin. Each page has a breadcrumb, a live date/clock with latitude and longitude, a QR code (bottom-right) and a grey 80% loading overlay with a gradient spinner.
- **Six-Language UI with Day/Night Mode**: English, Español, Deutsch, हिन्दी, العربية and Français from one merged string table (`app_strings.dart`, built from the former `.arb` files), plus a Material day/night switch. Arabic renders right-to-left.
- **Transparent Sprite Sheet Overlays**: Dynamic multi-frame sprite animations (`sprite-01.png` to `sprite--07.png`) mapped smoothly behind 3D models with transparent channels.
- **Media Galleries**: A vertical parallax picture carousel with pinch and double-tap zoom (animated GIF on double tap), seven autoplaying muted local videos with fullscreen, and seven Vimeo players.
- **Booking Agenda to Charts**: Pick a date, time (spinner time picker) and service type (React Native, Android, iOS, SwiftUI, Flutter, .NET), add notes, and the saved booking is drawn as ten charts: line, histogram, stacked area, bubble, 3D columns, pie, word cloud, flowchart, multi-axis and scatter.
- **Local SQLite Storage**: Bookings, timestamped notes (humanized with `timeago`) and salted-hash admin credentials stored with `sqflite`, with an admin login and panel.
- **Per-Page Publishing**: An auto-generated PDF for every page, an RSS 2.0 feed for every page (RSS icon on the Contact page), social sharing (LinkedIn, WhatsApp, mail) and a generated `sitemap.xml`.
- **Parallel.ai Search Integration**: Real-time concurrent multi-stream queries (`Future.wait`) combining Open-Meteo weather forecasts and Parallel.ai search payloads.
- **Columnar Database & Grafana MCP**: High-throughput analytical logging and metrics processed via a containerized OLAP backend and visualized through a half-transparent glassmorphism dashboard HUD.
- **Cross-Platform Web Ready**: Fully optimized for modern web browsers with responsive layout scaling.

## Tech Stack

- **Framework**: [Flutter Web](https://flutter.dev) (v3.0+)
- **Language**: [Dart](https://dart.dev)
- **3D Rendering**: `model_viewer_plus` (Google Model Viewer wrapper)
- **Networking & Concurrency**: `dio` with asynchronous parallel stream handling (`Future.wait`)
- **AI & Analytics**: Parallel.ai Search API, Open-Meteo API, Columnar DB, Grafana MCP Server
- **Icons & Styling**: `font_awesome_flutter`, custom `CustomPainter` glassmorphism widgets

## Project Structure

```
animation-panoramas-website/
├── assets/
│   ├── models/            # .glb 3D asset files
│   ├── sprites/           # multi-frame sprite sheets
│   └── videos/            # scene-01.mp4 ... scene-07.mp4
├── lib/
│   ├── data/
│   │   ├── ecosystems.dart     # Biome definitions, coords, and metadata mappings
│   │   └── network/
│   │       └── dio_client.dart # Shared Dio client
│   ├── l10n/
│   │   └── app_strings.dart    # Localization delegate + merged 6-language strings, language menu list
│   ├── models/
│   │   └── ecosystem.dart      # Core data models and background schemas
│   ├── pages/
│   │   ├── home_page.dart              # Metrics page (weather, Grafana MCP, telemetry widgets only)
│   │   ├── scenes_pages.dart           # Responsive scenes grid + one detail page per scene
│   │   ├── media_pages.dart            # Pictures carousel (zoom), local videos, Vimeo videos
│   │   ├── about_contact_pages.dart    # Animated counters, contact, RSS list
│   │   ├── services_agenda_pages.dart  # App-dev services table + calendar booking agenda
│   │   ├── notes_page.dart             # SQLite notes with timeago
│   │   ├── charts_page.dart            # Ten charts built from bookings
│   │   └── admin_pdf_pages.dart        # PDF library, admin login and panel
│   ├── screens/
│   │   └── home_screen.dart    # Landing overview generated from the page registry
│   ├── services/
│   │   ├── api_service.dart        # Legacy telemetry connectors
│   │   ├── olap_service.dart       # Parallel.ai concurrent analytics
│   │   ├── db_service.dart         # SQLite: admins, notes, bookings
│   │   └── rss_pdf_service.dart    # Per-page RSS 2.0 and PDF generation
│   ├── widgets/
│   │   ├── grafana_mcp_dashboard_widget.dart # Frosted glassmorphism HUD dashboard
│   │   ├── sprite_sheet_animator.dart        # Custom sprite painter & controller
│   │   ├── page_shell.dart                   # Shared page frame: clock, breadcrumb, QR, loading overlay, drawer
│   │   ├── animated_switcher_translation.dart# Language menu and day/night switch
│   │   ├── textured_button.dart              # Gradient + texture "More" button
│   │   ├── time_spinner_block.dart           # Spinner time picker + duration wheel
│   │   └── share_bar.dart                    # LinkedIn / WhatsApp / mail sharing adapter
│   ├── app_state.dart          # Global locale and theme-mode notifiers
│   ├── pages_registry.dart     # Single page list feeding drawer, PDFs, RSS and sitemap
│   └── main.dart               # App entry point, localization setup, bottom nav and scene viewer with metrics UI
├── web/
│   └── index.html         # Web host template containing model-viewer scripts
├── docker-compose.yml     # Grafana MCP container cluster configuration
├── schema.sql             # columnar analytical table definitions
├── pubspec.yaml           # Project dependencies and asset declarations
└── README.md
```

## Local Deployment & Docker Services

To spin up the local OLAP database and Grafana MCP server infrastructure:

```bash
docker-compose up -d
```

To run the Flutter Web application locally:

```bash
flutter pub get
flutter run -d chrome
```
