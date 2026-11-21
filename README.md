# Ecosystem Viewer & OLAP Telemetry Platform (Flutter Web)

An advanced, responsive 3D and 2D ecosystem and panorama explorer built with Flutter Web, featuring containerized real-time telemetry pipelines. This application allows users to seamlessly navigate through global biomes, render interactive 3D `.glb` models, run transparent sprite-sheet animations, and monitor real-time AI-augmented ecological metrics via Parallel.ai, Open-Meteo, ClickHouse OLAP, and Grafana MCP.

## Key Features

- **3D & 2D Biome Navigation**: Switch dynamically between global environments like Jungle Forests, Ocean Floors, Cloud Forests, and Seagrass Meadows. Every scene has its own page, opened with the textured "More" button next to the scene name.
- **Multi-Page Application**: Home overview, Main scene viewer, Metrics, Scenes (responsive grid), Pictures, Videos, Videos Vimeo, About, Contact, App Dev Services, Coding Agenda, Notes, Chart, PDF Library and Admin. Each page has a breadcrumb, a live date/clock with latitude and longitude, a QR code (bottom-right) and a grey 80% loading overlay with a gradient spinner.
- **Six-Language UI with light/dark Mode**: English, Español, Deutsch, हिन्दी, العربية and Français from one merged string table (`app_strings.dart`, built from the former `.arb` files), plus a Material light/dark switch. Arabic renders right-to-left.
- **Transparent Sprite Sheet Overlays**: Dynamic multi-frame sprite animations (`sprite-01.png` to `sprite--07.png`) mapped smoothly behind 3D models with transparent channels.
- **Media Galleries**: A vertical parallax picture carousel with pinch and double-tap zoom (animated GIF on double tap), seven autoplaying muted local videos with fullscreen, and seven Vimeo players.
- **Booking Agenda to Charts**: Pick a date, time (spinner time picker) and service type (React Native, Android, iOS, SwiftUI, Flutter, .NET), add notes, and the saved booking is drawn as ten charts: line, histogram, stacked area, bubble, 3D columns, pie, word cloud, flowchart, multi-axis and scatter.
- **Local SQLite Storage**: Bookings, timestamped notes (humanized with `timeago`) and salted-hash admin credentials stored with `sqflite`, with an admin login and panel.
- **Per-Page Publishing**: An auto-generated PDF for every page, an RSS 2.0 feed for every page (RSS icon on the Contact page), social sharing (LinkedIn, WhatsApp, mail) and a generated `sitemap.xml`.
- **Parallel.ai Search Integration**: Real-time concurrent multi-stream queries (`Future.wait`) combining Open-Meteo weather forecasts and Parallel.ai search payloads.
- **Columnar Database & Grafana MCP**: High-throughput analytical logging and metrics processed via a containerized OLAP backend and visualized through a half-transparent glassmorphism dashboard HUD.
- **Cross-Platform Web Ready**: Fully optimized for modern web browsers with responsive layout scaling.
- **Telemetry Observability Hub**: A diagnostics view (`telemetry_observability_widget.dart`) paired with a carousel (`telemetry_carousel.dart`) that cycles through telemetry panels, alongside the `ClimateNavBar`, `SourceCard`, `DatasetTableCard` and `LiveTelemetryCard` building blocks (`telemetry_widgets.dart`).
- **Real-Time Environmental Data Widgets**: Dedicated live data display widgets (`live_data_widgets.dart`) plus a Live Open-Meteo weather and environmental data widget (`open_meteo_live_widget.dart`) for on-screen real-time conditions.
- **Ecosystem Sprite Asset Loading**: A dedicated sprite asset loader (`ecosystem_sprite_loader.dart`) for ecosystem scenes, feeding the custom sprite painter & controller.
- **Contextual Snackbar Notifications**: A `snack.dart` helper delivering contextual snackbar notifications across the app.
- **Scene Video Preview Carousel**: A scene video carousel (`scene_video_carousel.dart`) with a platform I/O playback implementation (`scene_video_carousel_io.dart`) and a web/stub fallback (`scene_video_carousel_stub.dart`).
- **Custom Canvas Chart Suite**: Native canvas-rendered visualizations — a generic canvas chart renderer (`data_canvas_chart.dart`), temperature series chart (`temperature_canvas_chart.dart`), precipitation charts (`precipitation_charts.dart`), vegetation index and cover charts (`vegetation_charts.dart`) and drought monitoring graphs (`drought_graphs.dart`).
- **Centralized App Theme & Automatic Light/Dark Mode**: A single source-of-truth theme (`theme/app_theme.dart`) defining the Material light/dark palettes, and an automatic theme switcher (`theme/day_evening_auto.dart`) that toggles the theme based on the time of day, complementing the manual light/dark switch.

### NASA Earth Science & Satellite Data Pages

The application includes four specialized analytics pages powered by NASA satellite missions and global environmental datasets:

- **Precipitation** (`precipitation.dart`)
   - **Variable:** Global precipitation anomaly by year
   - **Data Source:** [NASA Goddard GPCP (Global Precipitation Climatology Project)](https://disc.gsfc.nasa.gov/) Monthly and Daily versions, research insights via [NASA Goddard Precipitation Research](https://earth.gsfc.nasa.gov/meso/research/precipitation), and cross-checked using the [GPM IMERG Data Directory](https://gpm.nasa.gov/node/3037) (including historical TRMM-era records back to 1998).
   - **Features:** Visualizes global-average monthly precipitation over land and ocean, tracking long-term anomalies.

- **Temperature** (`temperature.dart`)
   - **Variable:** Global temperature anomaly by decade
   - **Data Source:** [DataHub Core Global Temperature / NASA GISS Report](https://datahub.io/core/global-temp/UPDATE_SCRIPT_MAINTENANCE_REPORT).
   - **Features:** Structured breakdown of decadal temperature deviations across Northern and Southern hemispheres relative to historical baselines.

- **Vegetation** (`vegetation.dart`)
   - **Variable:** Vegetation index trend by continent
   - **Data Source:** [NASA Earth Observatory](https://earthobservatory.nasa.gov/global-maps/MOD_NDVI_M/GPM_3IMERGM) (measured via Terra satellite), [Sentinel Hub Space Apps Data Offer](https://www.sentinel-hub.com/spaceapps-data/), and the [Space Apps 2020 Resources Page](https://2020.spaceappschallenge.org/challenges/observe/scanning-lifeforms/resources) (NASA GIBS, Worldview, and Earthdata Search).
   - **Features:** Evaluates canopy health, vegetative growth trends, and rainfall response indexes worldwide.

- **Drought** (`drought.dart`)
   - **Variable:** Soil moisture anomaly by region
   - **Data Source:** [NASA SMAP (Soil Moisture Active Passive) Research Article (PMC7931972)](https://pmc.ncbi.nlm.nih.gov/articles/PMC7931972/) and high-resolution radiometer/radar metrics.
   - **Features:** Monitors surface layer and root zone soil moisture content, categorizing regional drought severity and risk levels.

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
│   │   ├── telemetry_datasets.dart # Typed tables behind the NASA pages, with CSV export
│   │   └── network/
│   │       └── dio_client.dart # Shared Dio client
│   ├── l10n/
│   │   └── app_strings.dart    # Localization delegate + merged 6-language strings, language menu list
│   ├── models/
│   │   └── ecosystem.dart      # Core data models and background schemas
│   ├── pages/
│   │   ├── about_company.dart    # Animated counters, contact, RSS list
│   │   ├── charts.dart           # Ten charts built from bookings
│   │   ├── drought.dart          # Drought severity & index assessment
│   │   ├── home.dart             # Metrics page (weather, Grafana MCP, telemetry widgets only)
│   │   ├── media.dart            # Pictures carousel (zoom), local videos, Vimeo videos
│   │   ├── notes.dart            # SQLite notes with timeago
│   │   ├── pdf_library.dart      # PDF library, admin login and panel
│   │   ├── precipitation.dart    # Precipitation analysis & monitoring
│   │   ├── scenes.dart           # Responsive scenes grid + one detail page per scene
│   │   ├── services_agenda.dart  # App-dev services table + calendar booking agenda
│   │   ├── temperature.dart      # Temperature tracking & trends
│   │   └── vegetation.dart       # Vegetation health & NDVI indicators
│   ├── screens/
│   │   └── home_screen.dart    # Landing overview generated from the page registry
│   ├── theme/
│   │   ├── app_theme.dart                       # Central light/dark Material theme definitions
│   │   └── day_evening_auto.dart                # Automatic theme switching by time of day
│   ├── services/
│   │   ├── api_service.dart        # Legacy telemetry connectors
│   │   ├── olap_service.dart       # Parallel.ai concurrent analytics
│   │   ├── db_service.dart         # SQLite: admins, notes, bookings
│   │   └── rss_pdf_service.dart    # Per-page RSS 2.0 and PDF generation
│   ├── widgets/
│   │   ├── animated_switcher_translation.dart# Language menu and light/dark switch
│   │   ├── charts/
│   │   │   ├── data_canvas_chart.dart         # Custom canvas chart renderer
│   │   │   ├── drought_graphs.dart            # Drought monitoring graphs and indicators
│   │   │   ├── precipitation_charts.dart      # Precipitation visualization charts
│   │   │   ├── temperature_canvas_chart.dart  # Temperature series canvas chart
│   │   │   └── vegetation_charts.dart         # Vegetation index and cover charts
│   │   ├── ecosystem_sprite_loader.dart       # Sprite asset loader for ecosystem scenes
│   │   ├── grafana_mcp_dashboard_widget.dart  # Frosted glassmorphism HUD dashboard
│   │   ├── live_data_widgets.dart             # Real-time environmental data display widgets
│   │   ├── open_meteo_live_widget.dart        # Live Open-Meteo weather & environmental data widget
│   │   ├── page_shell.dart                    # Shared page frame: clock, breadcrumb, QR, loading overlay, drawer
│   │   ├── scene_video_carousel.dart          # Scene video preview carousel
│   │   ├── scene_video_carousel_io.dart       # Platform I/O video playback implementation
│   │   ├── scene_video_carousel_stub.dart     # Web/stub fallback for scene video carousel
│   │   ├── share_bar.dart                     # LinkedIn / WhatsApp / mail sharing adapter
│   │   ├── snack.dart                   # Contextual snackbar notification helper
│   │   ├── sprite_sheet_animator.dart         # Custom sprite painter & controller
│   │   ├── structured_table.dart              # Table cards, DataPageBody banner, styled cells
│   │   ├── telemetry_carousel.dart            # Carousel cycling through telemetry panels
│   │   ├── telemetry_observability_widget.dart# Telemetry observability view and diagnostics
│   │   ├── telemetry_widgets.dart             # ClimateNavBar, SourceCard, DatasetTableCard, LiveTelemetryCard
│   │   ├── textured_button.dart               # Gradient + texture "More" button
│   │   └── time_spinner_block.dart            # Spinner time picker + duration wheel
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

## Web build: required SQLite files

`sqflite_common_ffi_web` needs two files in `web/` or every database page
(Notes, Chart, Coding Agenda, Admin) shows the loading spinner forever.
Run once from the project root, then rebuild:

```
dart run sqflite_common_ffi_web:setup
flutter build web --release
```







