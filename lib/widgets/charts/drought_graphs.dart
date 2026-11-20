import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';

import '../../data/telemetry_sections.dart';

class _DroughtGraph extends StatelessWidget {
  const _DroughtGraph({required this.vertexes, required this.edges, required this.tagColors, this.height = 320});

  final List<Map<String, String>> vertexes;
  final List<Map<String, String>> edges;
  final Map<String, Color> tagColors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final data = {
      'vertexes': [
        for (final v in vertexes) {'id': v['id'], 'tag': v['tag'], 'tags': [v['tag']]},
      ],
      'edges': [
        for (var i = 0; i < edges.length; i++)
          {'srcId': edges[i]['src'], 'dstId': edges[i]['dst'], 'edgeName': edges[i]['name'] ?? '', 'ranking': i},
      ],
    };
    return SizedBox(
      height: height,
      child: ClipRect(
        child: FlutterGraphWidget(
          data: data,
          algorithm: CircleLayout(),
          convertor: MapConvertor(),
          options: Options()
            ..enableHit = true
            ..graphStyle = (GraphStyle()..tagColor = tagColors),
        ),
      ),
    );
  }
}

class SoilMoistureGraph extends StatelessWidget {
  const SoilMoistureGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final vertexes = <Map<String, String>>[
      {'id': 'Soil moisture', 'tag': 'hub'},
    ];
    final edges = <Map<String, String>>[];
    for (final f in soilMoistureFindings) {
      final region = '${f.$1.split(',').first} ${f.$2}';
      vertexes
        ..add({'id': region, 'tag': 'region'})
        ..add({'id': f.$3, 'tag': 'finding'});
      edges
        ..add({'src': 'Soil moisture', 'dst': region, 'name': 'region'})
        ..add({'src': region, 'dst': f.$3, 'name': 'finding'});
    }
    return _DroughtGraph(
      vertexes: vertexes,
      edges: edges,
      tagColors: {'hub': Colors.brown, 'region': Colors.amber.shade800, 'finding': Colors.red.shade400},
    );
  }
}

class RainfallGraph extends StatelessWidget {
  const RainfallGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final vertexes = <Map<String, String>>[
      {'id': 'Annual rainfall', 'tag': 'hub'},
    ];
    final edges = <Map<String, String>>[];
    for (final e in annualRainfallMm.entries) {
      final value = '${e.key}: ${e.value.toStringAsFixed(0)} mm';
      vertexes
        ..add({'id': e.key, 'tag': e.value < 250 ? 'low' : 'area'})
        ..add({'id': value, 'tag': e.value < 250 ? 'low' : 'value'});
      edges
        ..add({'src': 'Annual rainfall', 'dst': e.key, 'name': 'area'})
        ..add({'src': e.key, 'dst': value, 'name': 'mm'});
    }
    return _DroughtGraph(
      vertexes: vertexes,
      edges: edges,
      tagColors: {
        'hub': Colors.cyan.shade800,
        'area': Colors.cyan.shade600,
        'value': Colors.teal,
        'low': Colors.deepOrange,
      },
    );
  }
}

class WinterWheatGraph extends StatelessWidget {
  const WinterWheatGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final vertexes = <Map<String, String>>[];
    final edges = <Map<String, String>>[];
    String? prev;
    for (final w in winterWheat2018) {
      final report = '${w.$1} report';
      final outlook = '${w.$1}: ${w.$4}';
      vertexes
        ..add({'id': report, 'tag': 'report'})
        ..add({'id': outlook, 'tag': w.$2 >= 0 ? 'up' : 'down'});
      edges.add({
        'src': report,
        'dst': outlook,
        'name': 'crop ${w.$2 >= 0 ? '+' : ''}${w.$2}%, area ${w.$3 >= 0 ? '+' : ''}${w.$3}%'
      });
      if (prev != null) edges.add({'src': prev, 'dst': report, 'name': 'next'});
      prev = report;
    }
    return _DroughtGraph(
      vertexes: vertexes,
      edges: edges,
      tagColors: {'report': Colors.deepOrange.shade700, 'up': Colors.green.shade600, 'down': Colors.red.shade400},
    );
  }
}

class California2015Graph extends StatelessWidget {
  const California2015Graph({super.key});

  @override
  Widget build(BuildContext context) {
    final vertexes = <Map<String, String>>[
      {'id': 'California 2015', 'tag': 'hub'},
    ];
    final edges = <Map<String, String>>[];
    for (final c in california2015) {
      final label = '${c.$1}: ${c.$3}';
      vertexes.add({'id': label, 'tag': c.$2 < 0 ? 'bad' : 'measure'});
      edges.add({'src': 'California 2015', 'dst': label, 'name': ''});
    }
    return _DroughtGraph(
      vertexes: vertexes,
      edges: edges,
      tagColors: {'hub': Colors.purple.shade700, 'measure': Colors.purple.shade300, 'bad': Colors.red.shade500},
    );
  }
}
