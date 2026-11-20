import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/telemetry_sections.dart';
import '../../data/telemetry_datasets.dart';

class _Point {
  final String x;
  final double y;
  final Color? color;
  const _Point(this.x, this.y, [this.color]);
}

class GreennessLines extends StatelessWidget {
  const GreennessLines({super.key});

  static const _decades = ['2000s', '2010s', '2020s'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        legend: const Legend(isVisible: true, position: LegendPosition.bottom, overflowMode: LegendItemOverflowMode.wrap),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
        primaryYAxis: const NumericAxis(minimum: 0.25, maximum: 0.65, interval: 0.1, title: AxisTitle(text: 'Greenness index')),
        series: <CartesianSeries<_Point, String>>[
          for (final e in vegetationIndexByContinent.entries)
            LineSeries<_Point, String>(
              name: e.key,
              dataSource: [for (var i = 0; i < _decades.length; i++) _Point(_decades[i], e.value[i])],
              xValueMapper: (p, _) => p.x,
              yValueMapper: (p, _) => p.y,
              markerSettings: const MarkerSettings(isVisible: true),
            ),
        ],
      ),
    );
  }
}

class TrendRankingBars extends StatelessWidget {
  const TrendRankingBars({super.key});

  @override
  Widget build(BuildContext context) {
    final rank = vegetationTrendRanking();
    final data = [
      for (final r in rank) _Point(r.key, r.value, r.value >= 0 ? Colors.green.shade600 : Colors.red.shade600),
    ];
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: const CategoryAxis(isInversed: true, majorGridLines: MajorGridLines(width: 0)),
        primaryYAxis: const NumericAxis(title: AxisTitle(text: 'Change in index'), minimum: -0.04, maximum: 0.08),
        series: <CartesianSeries<_Point, String>>[
          BarSeries<_Point, String>(
            dataSource: data,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            pointColorMapper: (p, _) => p.color,
            borderRadius: BorderRadius.circular(4),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            dataLabelMapper: (p, _) => (p.y >= 0 ? '+' : '') + p.y.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }
}

class IndexCoverDonut extends StatelessWidget {
  const IndexCoverDonut({super.key});

  static final _colors = [
    Colors.brown.shade300,
    Colors.yellow.shade700,
    Colors.lightGreen,
    Colors.green.shade900,
  ];

  @override
  Widget build(BuildContext context) {
    final data = [
      for (var i = 0; i < vegetationCover.length; i++)
        _Point('${vegetationCover[i].$1}: ${vegetationCover[i].$2}', vegetationCover[i].$3, _colors[i]),
    ];
    return SizedBox(
      height: 320,
      child: SfCircularChart(
        legend: const Legend(isVisible: true, position: LegendPosition.bottom, overflowMode: LegendItemOverflowMode.wrap),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<_Point, String>>[
          DoughnutSeries<_Point, String>(
            dataSource: data,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            pointColorMapper: (p, _) => p.color,
            innerRadius: '45%',
            dataLabelMapper: (p, _) => p.y.toStringAsFixed(1),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }
}
