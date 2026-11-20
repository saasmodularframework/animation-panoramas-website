import 'package:flutter/material.dart';

import '../data/telemetry_datasets.dart';
import '../widgets/telemetry_widgets.dart';
import '../widgets/live_data_widgets.dart';
import '../widgets/page_shell.dart';
import '../widgets/structured_table.dart';
import '../widgets/charts/temperature_canvas_chart.dart';

class TemperaturePage extends StatelessWidget {
  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade700;

    return PageShell(
      slug: 'temperature',
      title: 'Temperature',
      crumbs: const ['Earth Science', 'Temperature'],
      crumbSlugs: const ['earth-science', null],
      bottom: const ClimateNavBar(current: 'temperature'),
      child: DataPageBody(
        title: 'Temperature',
        variable: 'Global temperature anomaly by decade',
        icon: Icons.thermostat,
        color: red,
        children: [
   
          LiveCards.globalTemperatureYears(red),
          LiveCards.globalTemperatureDecades(red),
          LiveCards.temperatureNow(red),

          TableCard(
            title: 'Temperature anomaly chart (canvas)',
            color: red,
            note: '*2020s = 2020-2025 only. Base period 1951-1980. Pick a data set, choose how many points to plot, '
                'then drag, rotate or draw on the canvas.',
            child: const TemperatureCanvasChart(),
          ),
          SourceCard(dataset: temperatureDataset, color: red),
        ],
      ),
    );
  }
}
