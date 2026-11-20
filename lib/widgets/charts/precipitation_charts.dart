import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/telemetry_sections.dart';
import '../../data/telemetry_datasets.dart';

const _wet = Color(0xFF1565C0);
const _dry = Color(0xFFE64A19);

AxisTitles _noTitles() => const AxisTitles(sideTitles: SideTitles(showTitles: false));

class PrecipitationYearBars extends StatelessWidget {
  const PrecipitationYearBars({super.key});

  @override
  Widget build(BuildContext context) {
    final e = precipitationAnomalyByYear.entries.toList();
    return SizedBox(
      height: 280,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 12, 4),
        child: BarChart(
          BarChartData(
            minY: -0.06,
            maxY: 0.06,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: _noTitles(),
              rightTitles: _noTitles(),
              leftTitles: AxisTitles(
                axisNameWidget: const Text('mm/day', style: TextStyle(fontSize: 11)),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: 0.02,
                  getTitlesWidget: (v, meta) =>
                      SideTitleWidget(meta: meta, child: Text(v.toStringAsFixed(2), style: const TextStyle(fontSize: 10))),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= e.length) return const SizedBox.shrink();
                    return SideTitleWidget(
                        meta: meta, child: Text("'${e[i].key % 100}", style: const TextStyle(fontSize: 10)));
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                  '${e[group.x].key}\n${rod.toY >= 0 ? '+' : ''}${rod.toY.toStringAsFixed(2)} mm/day',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < e.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: e[i].value,
                    width: 16,
                    color: e[i].value >= 0 ? _wet : _dry,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

class OceanLandGlobalScatter extends StatelessWidget {
  const OceanLandGlobalScatter({super.key});

  @override
  Widget build(BuildContext context) {
    final e = oceanLandGlobalAnomaly.entries.toList();
    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 12, 4),
        child: ScatterChart(
          ScatterChartData(
            minX: -0.5,
            maxX: e.length - 0.5,
            minY: -0.05,
            maxY: 0.05,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: _noTitles(),
              rightTitles: _noTitles(),
              leftTitles: AxisTitles(
                axisNameWidget: const Text('mm/day', style: TextStyle(fontSize: 11)),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: 0.025,
                  getTitlesWidget: (v, meta) =>
                      SideTitleWidget(meta: meta, child: Text(v.toStringAsFixed(3), style: const TextStyle(fontSize: 10))),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (v, meta) {
                    final i = v.round();
                    if ((v - i).abs() > 0.01 || i < 0 || i >= e.length) return const SizedBox.shrink();
                    return SideTitleWidget(meta: meta, child: Text(e[i].key, style: const TextStyle(fontWeight: FontWeight.w700)));
                  },
                ),
              ),
            ),
            scatterSpots: [
              for (var i = 0; i < e.length; i++)
                ScatterSpot(
                  i.toDouble(),
                  e[i].value,
                  dotPainter: FlDotCirclePainter(
                    radius: 14,
                    color: e[i].value > 0 ? _wet : (e[i].value < 0 ? _dry : Colors.indigo),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnomalyClassDonut extends StatelessWidget {
  const AnomalyClassDonut({super.key});

  static const _colors = [
    Color(0xFF0D47A1),
    Color(0xFF03A9F4), 
    Color(0xFFBDBDBD), 
    Color(0xFFFF9800),
    Color(0xFFBF360C), 
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Row(children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < anomalyClasses.length; i++)
                  PieChartSectionData(
                    value: anomalyClasses[i].$3,
                    color: _colors[i],
                    radius: 54,
                    title: anomalyClasses[i].$1.split(' ').last,
                    titleStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _colors[i].computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < anomalyClasses.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${anomalyClasses[i].$1}: ${anomalyClasses[i].$2}', style: const TextStyle(fontSize: 12)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}
