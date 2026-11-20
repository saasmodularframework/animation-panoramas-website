import 'package:flutter/material.dart';
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor.dart';

import '../../data/telemetry_sections.dart';
import '../../data/telemetry_datasets.dart';

int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

class _Series {
  final String label;
  final List<MapEntry<String, double>> points;
  const _Series(this.label, this.points);
}


class TemperatureCanvasChart extends StatefulWidget {
  const TemperatureCanvasChart({super.key});

  @override
  State<TemperatureCanvasChart> createState() => _TemperatureCanvasChartState();
}

class _TemperatureCanvasChartState extends State<TemperatureCanvasChart> {
  static const double _canvasHeight = 340;
  static const double _plotTop = 30;
  static const double _plotHeight = 230;

  late final List<_Series> _series = [
    _Series('Decade mean (\u00B0C)', temperatureAnomalyByDecade.entries.toList()),
    _Series('Change from previous decade (\u00B0C)', temperatureDecadeChange()),
    _Series('Ten warmest years (\u00B0C)', [for (final e in warmestYears.entries) MapEntry('${e.key}', e.value)]),
  ];

  late final CanvasController _controller;
  int _which = 0;
  int _count = 8;
  double _width = 0;
  bool _drawing = false, _erasing = false;

  _Series get _cur => _series[_which];

  @override
  void initState() {
    super.initState();
    _controller = CanvasController((png) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chart exported as PNG (${png.length} bytes)')));
    });
    _controller.setOnStateChanged((isDrawing, isErasing) {
      if (mounted) setState(() {
        _drawing = isDrawing;
        _erasing = isErasing;
      });
    });
    _count = _clampInt(_cur.points.length, 3, 8);
  }

  void _plot() {
    if (_width <= 0) return;
    _controller.clearAll();
    final pts = _cur.points.take(_count).toList();
    final vals = pts.map((e) => e.value).toList();
    final hi = vals.fold<double>(0, (a, b) => b > a ? b : a);
    final lo = vals.fold<double>(0, (a, b) => b < a ? b : a);
    final span = (hi - lo) == 0 ? 1.0 : hi - lo;
    final k = _plotHeight / span;
    final baseY = _plotTop + hi * k;
    final slot = (_width - 24) / pts.length;
    final barW = (slot * 0.62).clamp(10.0, 56.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = 0; i < pts.length; i++) {
        final v = pts[i].value;
        final h = (v.abs() * k).clamp(2.0, _plotHeight);
        final x = 12 + slot * i + (slot - barW) / 2;
        final color = v >= 0 ? Colors.deepOrange.shade600 : Colors.indigo.shade400;
        final value = Text((v >= 0 ? '+' : '') + v.toStringAsFixed(2),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87));
        final bar = Container(
          width: barW,
          height: h,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        );
        _controller.addComponent(
          SizedBox(
            width: barW + 14,
            height: h + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: v >= 0 ? [value, bar] : [bar, value],
            ),
          ),
          Offset(x - 7, v >= 0 ? baseY - h - 16 : baseY),
        );
        _controller.addComponent(
          SizedBox(
            width: slot,
            child: Text(pts[i].key,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          Offset(12 + slot * i, _canvasHeight - 36),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _cur.points.length;
    final minCount = 3;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, children: [
        for (var i = 0; i < _series.length; i++)
          ChoiceChip(
            label: Text(_series[i].label),
            selected: _which == i,
            onSelected: (_) {
              setState(() {
                _which = i;
                _count = _clampInt(_count, minCount, _series[i].points.length);
              });
              _plot();
            },
          ),
      ]),
      Row(children: [
        Text('Data points: $_count of $total', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
          child: Slider(
            min: minCount.toDouble(),
            max: total.toDouble(),
            divisions: total - minCount,
            value: _clampInt(_count, minCount, total).toDouble(),
            label: '$_count',
            onChanged: (v) {
              setState(() => _count = v.round());
              _plot();
            },
          ),
        ),
      ]),
      Wrap(spacing: 4, children: [
        IconButton(
          tooltip: 'Draw',
          isSelected: _drawing,
          icon: const Icon(Icons.edit),
          onPressed: () => _drawing ? _controller.disableDrawingErasing() : _controller.enableDrawing(),
        ),
        IconButton(
          tooltip: 'Erase',
          isSelected: _erasing,
          icon: const Icon(Icons.auto_fix_normal),
          onPressed: () => _erasing ? _controller.disableDrawingErasing() : _controller.enableErasing(),
        ),
        IconButton(tooltip: 'Undo', icon: const Icon(Icons.undo), onPressed: _controller.undo),
        IconButton(tooltip: 'Redo', icon: const Icon(Icons.redo), onPressed: _controller.redo),
        IconButton(tooltip: 'Re-plot', icon: const Icon(Icons.refresh), onPressed: _plot),
        IconButton(tooltip: 'Export PNG', icon: const Icon(Icons.image_outlined), onPressed: _controller.exportCanvas),
      ]),
      LayoutBuilder(builder: (context, box) {
        if ((box.maxWidth - _width).abs() > 1) {
          _width = box.maxWidth;
          WidgetsBinding.instance.addPostFrameCallback((_) => _plot());
        }
        return Container(
          height: _canvasHeight,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
          child: CanvasWidget(controller: _controller),
        );
      }),
    ]);
  }
}
