import 'package:flutter/material.dart';

import '../data/telemetry_datasets.dart';
import '../widgets/telemetry_widgets.dart';
import '../widgets/live_data_widgets.dart';
import '../widgets/page_shell.dart';
import '../widgets/structured_table.dart';
import '../data/telemetry_sections.dart' show annualRainfallMm, winterWheat2018, california2015;
import '../widgets/charts/data_canvas_chart.dart';
import '../widgets/charts/drought_graphs.dart';

class DroughtPage extends StatelessWidget {
  const DroughtPage({super.key});

  @override
  Widget build(BuildContext context) {
    final amber = Colors.amber.shade800;

    return PageShell(
      slug: 'drought',
      title: 'Drought',
      crumbs: const ['Earth Science', 'Drought'],
      crumbSlugs: const ['earth-science', null],
      bottom: const ClimateNavBar(current: 'drought'),
      child: DataPageBody(
        title: 'Drought',
        variable: 'Soil moisture anomaly by region',
        icon: Icons.landscape,
        color: amber,
        children: [
          // Live data first, then the static reference tables.
          LiveCards.droughtSoilMoisture(amber),
          // Table 1 - region summary
          TableCard(
            title: 'Reference: Soil moisture anomaly by region',
            color: amber,
            child: gridTable(
              headers: const ['Region', 'Year', 'Soil moisture'],
              headerColor: Colors.brown.shade800,
              zebra: Colors.amber.shade50,
              flex: const [1.5, 0.8, 2],
              rows: [
                [
                  cell('Western Cape, South Africa', bold: true, left: true),
                  cell('2017'),
                  pill('Driest since 1981', Colors.red.shade700),
                ],
                [
                  cell('New South Wales, Australia', bold: true, left: true),
                  cell('2018'),
                  pill('Worst of 2015-2018', Colors.deepOrange),
                ],
                [
                  cell('California, USA', bold: true, left: true),
                  cell('2015'),
                  pill('Below normal, then recovered', Colors.orange.shade700),
                ],
              ],
            ),
            
          ),

          TableCard(
            title: 'Graph: Soil moisture anomaly by region (flutter_graph_view)',
            color: amber,
            child: const SoilMoistureGraph(),
          ),


          TableCard(
            title: 'Reference: Average annual rainfall (mm)',
            color: Colors.cyan.shade700,
            note: 'Western Cape is far below the national average.',
            child: gridTable(
              headers: const ['Area', 'Rainfall'],
              headerColor: Colors.cyan.shade900,
              zebra: Colors.cyan.shade50,
              flex: const [1.5, 2],
              rows: [
                [cell('South Africa (national)', bold: true, left: true),
                  barCell(380, 400, Colors.cyan.shade700, '380')],
                [cell('New South Wales', bold: true, left: true),
                  barCell(365, 400, Colors.teal, '365')],
                [cell('Western Cape', bold: true, left: true),
                  barCell(185, 400, Colors.deepOrange, '185')],
              ],
            ),
          ),

          TableCard(
            title: 'Graph: Average annual rainfall (flutter_graph_view)',
            color: Colors.cyan.shade700,
            child: const RainfallGraph(),
          ),

   
          TableCard(
            title: 'Reference: Australia 2018 winter wheat, change vs last year',
            color: Colors.deepOrange.shade600,
            child: gridTable(
              headers: const ['Report', 'Crop', 'Area', 'Expected yield'],
              headerColor: Colors.deepOrange.shade900,
              zebra: Colors.deepOrange.shade50,
              flex: const [1.2, 0.8, 0.8, 1.8],
              rows: [
                [cell('Jul', bold: true), _chg('+3%'), _chg('-2%'), cell('+5%')],
                [cell('Sep', bold: true), _chg('-6%'), _chg('-10%'), cell('Same as last year')],
                [cell('Oct', bold: true), _chg('-13%'), _chg('-10%'), cell('18% below 5-yr avg')],
                [cell('Nov', bold: true), _chg('-18%'), _chg('-12%'), cell('21% below 5-yr avg')],
                [cell('Dec', bold: true), _chg('-20%'), _chg('-18%'), cell('17% below 5-yr avg')],
              ],
            ),
          ),

          TableCard(
            title: 'Graph: Australia 2018 winter wheat (flutter_graph_view)',
            color: Colors.deepOrange.shade600,
            child: const WinterWheatGraph(),
          ),

          TableCard(
            title: 'Reference: California 2015 and key figures',
            color: Colors.purple.shade600,
            child: gridTable(
              headers: const ['Measure', 'Value'],
              headerColor: Colors.purple.shade900,
              zebra: Colors.purple.shade50,
              flex: const [2, 1.4],
              rows: [
                [cell('Area in exceptional drought, early April', bold: true, left: true),
                  barCell(44, 50, Colors.red.shade700, '44%')],
                [cell('Area in exceptional drought, mid May', bold: true, left: true),
                  barCell(47, 50, Colors.red.shade900, '47%')],
                [cell('Water used for irrigation', bold: true, left: true),
                  barCell(41, 50, Colors.blue.shade700, '41%')],
                [cell('Wheat yield forecast, Western Cape', bold: true, left: true),
                  barCell(64, 70, Colors.deepOrange, '-64% vs 5-yr avg')],
                [cell('Almond yield, lb/acre (drought vs calm period)', bold: true, left: true),
                  cell('2,105 vs 2,215', bg: Colors.purple.shade100)],
              ],
            ),
          ),
          TableCard(
            title: 'Graph: California 2015 and key figures (flutter_graph_view)',
            color: Colors.purple.shade600,
            child: const California2015Graph(),
          ),

          TableCard(
            title: 'Canvas chart: choose data and how many points to plot',
            color: amber,
            child: DataCanvasChart(
              fileName: 'drought',
              initialColor: const Color(0xFFC62828),
              series: [
                ChartSeries('Annual rainfall (mm)', annualRainfallMm.entries.toList(), signed: false),
                ChartSeries('Winter wheat, crop change (%)', [for (final w in winterWheat2018) MapEntry(w.$1, w.$2.toDouble())]),
                ChartSeries('Winter wheat, area change (%)', [for (final w in winterWheat2018) MapEntry(w.$1, w.$3.toDouble())]),
                ChartSeries('California 2015 (%)', [
                  for (final (i, c) in california2015.take(4).indexed)
                    MapEntry(const ['Drought Apr', 'Drought May', 'Irrigation', 'Wheat WC'][i], c.$2),
                ]),
              ],
            ),
          ),
          SourceCard(dataset: droughtDataset, color: amber),
          DatasetTableCard(dataset: droughtDataset, color: amber, title: 'Reference snapshot (static), ${droughtDataset.unit}'),
        ],
      ),
    );
  }

  static Widget _chg(String s) =>
      cell(s, bg: s.startsWith('+') ? Colors.green.shade600 : Colors.red.shade400);
}
