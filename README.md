# Ecosystem Viewer & OLAP Telemetry Platform (Flutter Web)

An advanced, responsive 3D and 2D ecosystem and panorama explorer built with Flutter Web, featuring containerized real-time telemetry pipelines. This application allows users to seamlessly navigate through global biomes, render interactive 3D `.glb` models, run transparent sprite-sheet animations, and monitor real-time AI-augmented ecological metrics via Parallel.ai, Open-Meteo, ClickHouse OLAP, and Grafana MCP.

## Key Features

- **3D & 2D Biome Navigation**: Switch dynamically between global environments like Jungle Forests, Ocean Floors, Cloud Forests, and Seagrass Meadows.
- **Transparent Sprite Sheet Overlays**: Dynamic multi-frame sprite animations (`sprite-01.png` to `sprite-06.png`) mapped smoothly behind 3D models with transparent alpha channels.
- **Parallel.ai Agent Search Integration**: Real-time concurrent multi-stream queries (`Future.wait`) combining Open-Meteo weather forecasts and Parallel.ai agent deep-research search payloads.
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
│   └── sprites/           # multi-frame sprite sheets
├── lib/
│   ├── data/
│   │   └── ecosystems.dart     # Biome definitions, coords, and metadata mappings
│   ├── models/
│   │   └── ecosystem.dart      # Core data models and background schemas
│   ├── services/
│   │   ├── api_service.dart    # Legacy telemetry connectors
│   │   └── olap_service.dart   # Parallel.ai concurrent analytics
│   ├── widgets/
│   │   ├── grafana_mcp_dashboard_widget.dart # Frosted glassmorphism HUD dashboard
│   │   └── sprite_sheet_animator.dart        # Custom sprite painter & controller
│   └── main.dart               # Main app entry point and state coordinator
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
