import 'package:flutter/material.dart';

import '../data/telemetry_datasets.dart';
import '../l10n/app_strings.dart';
import '../widgets/telemetry_carousel.dart';
import '../widgets/page_shell.dart';
import '../widgets/structured_table.dart';

class EarthSciencePage extends StatelessWidget {
  const EarthSciencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final blue = Colors.indigo.shade700;
    return PageShell(
      slug: 'earth-science',
      title: 'Earth Science',
      crumbs: const ['Earth Science'],
      child: DataPageBody(
        title: 'NASA Earth Science',
        variable: 'Satellite missions and global environmental datasets',
        icon: Icons.public,
        color: blue,
        children: [
  
          ClimateCarousel(slug: 'precipitation', title: precipitationDataset.title, icon: Icons.water_drop, color: Colors.blue.shade700),
          ClimateCarousel(slug: 'temperature', title: temperatureDataset.title, icon: Icons.thermostat, color: Colors.red.shade700),
          ClimateCarousel(slug: 'vegetation', title: vegetationDataset.title, icon: Icons.eco, color: Colors.green.shade700),
          ClimateCarousel(slug: 'drought', title: droughtDataset.title, icon: Icons.landscape, color: Colors.amber.shade800),
        ],
      ),
    );
  }
}
