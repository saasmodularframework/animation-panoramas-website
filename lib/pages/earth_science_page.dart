import 'package:flutter/material.dart';

import '../data/telemetry_datasets.dart';
import '../widgets/telemetry_widgets.dart';
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
          ClimateHubCard(slug: 'precipitation', icon: Icons.water_drop, color: Colors.blue.shade700, dataset: precipitationDataset),
          ClimateHubCard(slug: 'temperature', icon: Icons.thermostat, color: Colors.red.shade700, dataset: temperatureDataset),
          ClimateHubCard(slug: 'vegetation', icon: Icons.eco, color: Colors.green.shade700, dataset: vegetationDataset),
          ClimateHubCard(slug: 'drought', icon: Icons.landscape, color: Colors.amber.shade800, dataset: droughtDataset),
        ],
      ),
    );
  }
}
