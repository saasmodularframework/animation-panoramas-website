import 'package:flutter/material.dart';

import '../data/telemetry_datasets.dart';
import '../widgets/telemetry_widgets.dart';
import '../widgets/live_data_widgets.dart';
import '../widgets/page_shell.dart';
import '../widgets/structured_table.dart';
import '../data/telemetry_sections.dart' show vegetationTrendRanking;
import '../widgets/charts/data_canvas_chart.dart';
import '../widgets/charts/vegetation_charts.dart';

class VegetationPage extends StatelessWidget {
  const VegetationPage({super.key});

  static const _data = vegetationIndexByContinent;

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;
    final ranked = _data.entries.toList()
      ..sort((a, b) => (b.value.last - b.value.first)
          .compareTo(a.value.last - a.value.first));

    return PageShell(
      slug: 'vegetation',
      title: 'Vegetation',
      crumbs: const ['Earth Science', 'Vegetation'],
      crumbSlugs: const ['earth-science', null],
      bottom: const ClimateNavBar(current: 'vegetation'),
      child: DataPageBody(
        title: 'Vegetation',
        variable: 'Vegetation index trend by continent',
        icon: Icons.eco,
        color: green,
        children: [

          LiveCards.vegetationNdvi(green),
          LiveCards.vegetationWaterSupply(green),
          LiveCards.vegetationWaterDemand(green),

          TableCard(
            title: 'Reference: Greenness index by continent and decade',
            color: green,
            sample: true,
            child: gridTable(
              headers: const ['Continent', '2000s', '2010s', '2020s'],
              headerColor: Colors.green.shade900,
              flex: const [1.6, 1, 1, 1],
              rows: [
                for (final e in _data.entries)
                  [
                    cell(e.key, bold: true, left: true),
                    for (final v in e.value)
                      cell(v.toStringAsFixed(2),
                          bg: scale((v - 0.25) / 0.40, const Color(0xFFE8D9A8),
                              Colors.green.shade900)),
                  ],
              ],
            ),
          ),

          TableCard(
            title: 'Chart: Greenness index by continent (Syncfusion)',
            color: green,
            child: const GreennessLines(),
          ),

          TableCard(
            title: 'Reference: Trend ranking (2000s to 2020s)',
            color: Colors.lime.shade800,
            sample: true,
            child: gridTable(
              headers: const ['#', 'Continent', 'Change'],
              headerColor: Colors.lime.shade900,
              zebra: Colors.lime.shade50,
              flex: const [0.5, 1.6, 2],
              rows: [
                for (var i = 0; i < ranked.length; i++)
                  [
                    cell('${i + 1}', bold: true),
                    cell(ranked[i].key, bold: true, left: true),
                    barCell(
                      ranked[i].value.last - ranked[i].value.first,
                      0.06,
                      ranked[i].value.last >= ranked[i].value.first
                          ? Colors.green.shade600
                          : Colors.red,
                      ((ranked[i].value.last - ranked[i].value.first) >= 0 ? '+' : '') +
                          (ranked[i].value.last - ranked[i].value.first).toStringAsFixed(2),
                    ),
                  ],
              ],
            ),
          ),

          TableCard(
            title: 'Chart: Trend ranking (Syncfusion)',
            color: Colors.lime.shade800,
            child: const TrendRankingBars(),
          ),

          TableCard(
            title: 'Reference: How to read the index',
            color: Colors.brown.shade600,
            child: gridTable(
              headers: const ['Index', 'Cover', 'Colour'],
              headerColor: Colors.brown.shade900,
              zebra: Colors.brown.shade50,
              flex: const [1, 2, 1],
              rows: [
                [cell('below 0.1', bold: true), cell('Bare ground, snow, water', left: true), cell('', bg: Colors.brown.shade300)],
                [cell('0.1 - 0.3', bold: true), cell('Sparse grass or shrub', left: true), cell('', bg: Colors.yellow.shade700)],
                [cell('0.3 - 0.6', bold: true), cell('Crops and moderate cover', left: true), cell('', bg: Colors.lightGreen)],
                [cell('above 0.6', bold: true), cell('Dense, healthy forest', left: true), cell('', bg: Colors.green.shade900)],
              ],
            ),
          ),
          TableCard(
            title: 'Chart: How to read the index (Syncfusion)',
            color: Colors.brown.shade600,
            child: const IndexCoverDonut(),
          ),

          TableCard(
            title: 'Canvas chart: choose data and how many points to plot',
            color: green,
            child: DataCanvasChart(
              fileName: 'vegetation',
              initialColor: const Color(0xFF2E7D32),
              series: [
                for (final (i, d) in const ['2000s', '2010s', '2020s'].indexed)
                  ChartSeries('Greenness index, $d', [for (final e in _data.entries) MapEntry(e.key, e.value[i])], signed: false),
                ChartSeries('Change 2000s to 2020s', vegetationTrendRanking()),
              ],
            ),
          ),
          SourceCard(dataset: vegetationDataset, color: green),
          DatasetTableCard(dataset: vegetationDataset, color: green, title: 'Reference snapshot (static), ${vegetationDataset.unit}'),
        ],
      ),
    );
  }
}
