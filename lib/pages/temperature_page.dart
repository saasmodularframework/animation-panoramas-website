import 'package:flutter/material.dart';
import '../widgets/structured_table.dart';


class TemperaturePage extends StatelessWidget {
  const TemperaturePage({super.key});

  static const _decades = <String, double>{
    '1880s': -0.212, '1890s': -0.237, '1900s': -0.313, '1910s': -0.327,
    '1920s': -0.236, '1930s': -0.122, '1940s': 0.043, '1950s': -0.048,
    '1960s': -0.030, '1970s': 0.034, '1980s': 0.247, '1990s': 0.385,
    '2000s': 0.589, '2010s': 0.804, '2020s*': 1.063,
  };

  static const _topYears = <int, double>{
    2024: 1.2817, 2025: 1.185, 2023: 1.1675, 2016: 1.01, 2020: 1.005,
    2019: 0.9775, 2017: 0.9125, 2015: 0.895, 2022: 0.89, 2018: 0.8483,
  };

  String _fmt(double v) => (v >= 0 ? '+' : '') + v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade700;
    final names = _decades.keys.toList();
    final vals = _decades.values.toList();
    final medals = [Colors.amber, Colors.blueGrey.shade300, Colors.brown.shade300];

    return PageShell(
      title: 'Temperature',
      variable: 'Global temperature anomaly by decade',
      icon: Icons.thermostat,
      color: red,
      children: [
        // Table 1 - heat + bars
        TableCard(
          title: 'Mean anomaly by decade (\u00B0C)',
          color: red,
          note: '*2020s = 2020-2025 only. Base period 1951-1980.',
          child: gridTable(
            headers: const ['Decade', '\u00B0C', 'Level'],
            headerColor: Colors.red.shade900,
            flex: const [1, 1, 2],
            rows: [
              for (var i = 0; i < names.length; i++)
                [
                  cell(names[i], bold: true),
                  cell(_fmt(vals[i]),
                      bg: scale((vals[i] + 0.4) / 1.5, Colors.indigo.shade400,
                          Colors.red.shade700, Colors.white)),
                  barCell(vals[i], 1.1,
                      vals[i] < 0 ? Colors.indigo : Colors.deepOrange, _fmt(vals[i])),
                ],
            ],
          ),
        ),

        TableCard(
          title: 'Change from previous decade',
          color: Colors.deepPurple.shade600,
          child: gridTable(
            headers: const ['Decade', 'Change (\u00B0C)', 'Trend'],
            headerColor: Colors.deepPurple.shade900,
            zebra: Colors.deepPurple.shade50,
            rows: [
              for (var i = 1; i < names.length; i++)
                [
                  cell(names[i], bold: true),
                  cell(_fmt(vals[i] - vals[i - 1])),
                  pill(
                    vals[i] - vals[i - 1] >= 0 ? '\u25B2 warmer' : '\u25BC cooler',
                    vals[i] - vals[i - 1] >= 0 ? Colors.deepOrange : Colors.blue.shade600,
                  ),
                ],
            ],
          ),
        ),

        TableCard(
          title: 'Ten warmest years',
          color: Colors.amber.shade800,
          child: gridTable(
            headers: const ['Rank', 'Year', 'Anomaly (\u00B0C)'],
            headerColor: Colors.brown.shade800,
            zebra: Colors.amber.shade50,
            rows: [
              for (var i = 0; i < _topYears.length; i++)
                [
                  cell('${i + 1}',
                      bold: true, bg: i < 3 ? medals[i] : null),
                  cell('${_topYears.keys.elementAt(i)}', bold: true),
                  cell(_fmt(_topYears.values.elementAt(i)),
                      bg: scale((_topYears.values.elementAt(i) - 0.8) / 0.5,
                          Colors.orange.shade200, Colors.red.shade800)),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
