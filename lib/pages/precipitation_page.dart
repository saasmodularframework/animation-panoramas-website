import 'package:flutter/material.dart';

import '../data/telemetry_datasets.dart';
import '../widgets/telemetry_widgets.dart';
import '../widgets/live_data_widgets.dart';
import '../widgets/page_shell.dart';
import '../widgets/structured_table.dart';
import '../data/telemetry_sections.dart' show anomalyClasses, oceanLandGlobalAnomaly;
import '../widgets/charts/data_canvas_chart.dart';
import '../widgets/charts/precipitation_charts.dart';

class PrecipitationPage extends StatelessWidget {
  const PrecipitationPage({super.key});

  static const double _globalMean = globalMeanPrecipitation; 
  static const _years = precipitationAnomalyByYear;

  @override
  Widget build(BuildContext context) {
    final blue = Colors.blue.shade700;

    return PageShell(
      slug: 'precipitation',
      title: 'Precipitation',
      crumbs: const ['Earth Science', 'Precipitation'],
      crumbSlugs: const ['earth-science', null],
      bottom: const ClimateNavBar(current: 'precipitation'),
      child: DataPageBody(
        title: 'Precipitation',
        variable: 'Global precipitation anomaly by year',
        icon: Icons.water_drop,
        color: blue,
        children: [
          // Live data first, then the static reference tables.
          LiveCards.precipitationNow(blue),

          TableCard(
            title: 'Reference: Anomaly by year',
            color: blue,
            sample: true,
            note: 'Anomaly = yearly mean minus long-term mean ($_globalMean mm/day).',
            child: gridTable(
              headers: const ['Year', 'mm/day', '% of mean', 'Status'],
              headerColor: Colors.blue.shade900,
              flex: const [1, 1.2, 1.2, 1.4],
              rows: [
                for (final e in _years.entries)
                  [
                    cell('${e.key}', bold: true),
                    cell(
                      (e.value >= 0 ? '+' : '') + e.value.toStringAsFixed(2),
                      bg: scale((e.value + 0.05) / 0.10, Colors.deepOrange.shade400,
                          Colors.blue.shade700, Colors.white),
                    ),
                    cell('${(e.value / _globalMean * 100).toStringAsFixed(1)}%'),
                    pill(
                      e.value > 0.015 ? 'Wet' : (e.value < -0.015 ? 'Dry' : 'Normal'),
                      e.value > 0.015
                          ? Colors.blue.shade600
                          : (e.value < -0.015 ? Colors.deepOrange : Colors.grey),
                    ),
                  ],
              ],
            ),
          ),

          TableCard(
            title: 'Chart: Anomaly by year (fl_chart)',
            color: blue,
            child: const PrecipitationYearBars(),
          ),

          TableCard(
            title: 'Reference: Ocean, land and global change',
            color: Colors.teal.shade700,
            sample: true,
            child: gridTable(
              headers: const ['Surface', 'Anomaly (mm/day)'],
              headerColor: Colors.teal.shade900,
              zebra: Colors.teal.shade50,
              flex: const [1, 2],
              rows: [
                [cell('Ocean', bold: true, left: true), barCell(0.02, 0.05, Colors.teal.shade600, '+0.02')],
                [cell('Land', bold: true, left: true), barCell(-0.03, 0.05, Colors.deepOrange, '-0.03')],
                [cell('Global', bold: true, left: true), barCell(0.00, 0.05, Colors.indigo, '0.00')],
              ],
            ),
          ),

          TableCard(
            title: 'Chart: Ocean, land and global change (fl_chart)',
            color: Colors.teal.shade700,
            child: const OceanLandGlobalScatter(),
          ),

          TableCard(
            title: 'Reference: Anomaly classes',
            color: Colors.indigo.shade600,
            note: 'Large anomalies on maps are usually +/-50% of a location\'s average.',
            child: gridTable(
              headers: const ['Class', 'Range', 'Colour'],
              headerColor: Colors.indigo.shade900,
              zebra: Colors.indigo.shade50,
              flex: const [1.4, 1.2, 1],
              rows: [
                [cell('Very wet', bold: true, left: true), cell('above +50%'), cell('', bg: Colors.blue.shade900)],
                [cell('Wet', bold: true, left: true), cell('+10% to +50%'), cell('', bg: Colors.lightBlue)],
                [cell('Normal', bold: true, left: true), cell('-10% to +10%'), cell('', bg: Colors.grey.shade300)],
                [cell('Dry', bold: true, left: true), cell('-50% to -10%'), cell('', bg: Colors.orange)],
                [cell('Very dry', bold: true, left: true), cell('below -50%'), cell('', bg: Colors.deepOrange.shade900)],
              ],
            ),
          ),
          TableCard(
            title: 'Chart: Anomaly classes (fl_chart)',
            color: Colors.indigo.shade600,
            child: const AnomalyClassDonut(),
          ),

          TableCard(
            title: 'Canvas chart: choose data and how many points to plot',
            color: blue,
            child: DataCanvasChart(
              fileName: 'precipitation',
              initialColor: const Color(0xFF1565C0),
              series: [
                ChartSeries('Anomaly by year (mm/day)', [for (final e in _years.entries) MapEntry('${e.key}', e.value)]),
                ChartSeries('Ocean / land / global (mm/day)', oceanLandGlobalAnomaly.entries.toList()),
                ChartSeries('Anomaly class share (%)', [for (final c in anomalyClasses) MapEntry(c.$1, c.$3)], signed: false),
              ],
            ),
          ),
          SourceCard(dataset: precipitationDataset, color: blue),
          DatasetTableCard(dataset: precipitationDataset, color: blue, title: 'Reference snapshot (static), ${precipitationDataset.unit}'),
        ],
      ),
    );
  }
}
