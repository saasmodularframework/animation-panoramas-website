import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_canvas_editor/flutter_advanced_canvas_editor.dart';

import '../../data/telemetry_sections.dart';
import '../../data/telemetry_datasets.dart';
import '../../utils/png_download.dart';

int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

class _Series {
  final String label;
  final List<MapEntry<String, double>> points;
  const _Series(this.label, this.points);
}

enum _ChartType { bars, line, area }

enum _LineStyle { solid, dashed, dotted, dashDot }

extension on _ChartType {
  String get label => switch (this) {
        _ChartType.bars => 'Bars',
        _ChartType.line => 'Line',
        _ChartType.area => 'Area',
      };
}

extension on _LineStyle {
  String get label => switch (this) {
        _LineStyle.solid => 'Solid',
        _LineStyle.dashed => 'Dashed',
        _LineStyle.dotted => 'Dotted',
        _LineStyle.dashDot => 'Dash-dot',
      };

  List<double>? pattern(double w) => switch (this) {
        _LineStyle.solid => null,
        _LineStyle.dashed => [w * 4, w * 3],
        _LineStyle.dotted => [0.01, w * 2.6],
        _LineStyle.dashDot => [w * 5, w * 2.6, 0.01, w * 2.6],
      };
}

const _palette = <(String, Color)>[
  ('Orange', Color(0xFFE65100)),
  ('Red', Color(0xFFC62828)),
  ('Blue', Color(0xFF1565C0)),
  ('Teal', Color(0xFF00796B)),
  ('Green', Color(0xFF2E7D32)),
  ('Purple', Color(0xFF6A1B9A)),
  ('Black', Color(0xFF212121)),
];

const _negativeColor = Color(0xFF3F51B5);

Color _inkStrong = Colors.black87;
Color _inkSoft = Colors.black54;
Color _gridInk = Colors.black12;

class _ChartStyle {
  final _ChartType type;
  final _LineStyle lineStyle;
  final Color color;
  final double density; 
  final double strokeWidth;
  final bool showValues;
  const _ChartStyle(this.type, this.lineStyle, this.color, this.density, this.strokeWidth, this.showValues);
}

class _ChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> pts;
  final _ChartStyle style;
  const _ChartPainter(this.pts, this.style);

  static const double _padL = 40, _padR = 16, _padT = 30, _padB = 44;

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty) return;
    final plot = Rect.fromLTRB(_padL, _padT, size.width - _padR, size.height - _padB);
    if (plot.width <= 0 || plot.height <= 0) return;

    var hi = pts.map((e) => e.value).fold<double>(0, math.max);
    var lo = pts.map((e) => e.value).fold<double>(0, math.min);
    final pad = (hi - lo) * 0.12;
    if (hi > 0) hi += pad;
    if (lo < 0) lo -= pad;
    final span = (hi - lo) == 0 ? 1.0 : hi - lo;
    double yOf(double v) => plot.top + (hi - v) / span * plot.height;

    final grid = Paint()
      ..color = _gridInk
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final v = lo + span * i / 4;
      final y = yOf(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, v.toStringAsFixed(1), Offset(plot.left - 6, y), 10, _inkSoft, FontWeight.w500, align: _A.right);
    }
  
    canvas.drawLine(
      Offset(plot.left, yOf(0)),
      Offset(plot.right, yOf(0)),
      Paint()
        ..color = _inkSoft
        ..strokeWidth = 1.4,
    );

    final n = pts.length;
    final slot = plot.width / n;
    double xOf(int i) => plot.left + slot * (i + 0.5);

    switch (style.type) {
      case _ChartType.bars:
        _bars(canvas, plot, slot, xOf, yOf);
      case _ChartType.line:
      case _ChartType.area:
        _lines(canvas, plot, xOf, yOf);
    }

    for (var i = 0; i < n; i++) {
      _text(canvas, pts[i].key, Offset(xOf(i), plot.bottom + 8), 10, _inkStrong, FontWeight.w600,
          align: _A.center, below: true);
    }
  }

  void _bars(Canvas canvas, Rect plot, double slot, double Function(int) xOf, double Function(double) yOf) {
    final barW = (slot * 0.62).clamp(10.0, 56.0);
    final zeroY = yOf(0);
    for (var i = 0; i < pts.length; i++) {
      final v = pts[i].value;
      final c = v >= 0 ? style.color : _negativeColor;
      final top = math.min(yOf(v), zeroY);
      final bottom = math.max(yOf(v), zeroY);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(xOf(i) - barW / 2, top, xOf(i) + barW / 2, math.max(bottom, top + 2)),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, Paint()..color = c.withValues(alpha: style.density));
      // outline carries the chosen line style
      final outline = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth
        ..strokeCap = style.lineStyle == _LineStyle.dotted ? StrokeCap.round : StrokeCap.butt;
      _strokePath(canvas, Path()..addRRect(rect), outline, style.lineStyle, style.strokeWidth);
      if (style.showValues) _value(canvas, v, Offset(xOf(i), v >= 0 ? top - 4 : bottom + 4), above: v >= 0);
    }
  }

  void _lines(Canvas canvas, Rect plot, double Function(int) xOf, double Function(double) yOf) {
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(xOf(i), yOf(pts[i].value));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    if (style.type == _ChartType.area) {
      final fill = Path.from(path)
        ..lineTo(xOf(pts.length - 1), yOf(0))
        ..lineTo(xOf(0), yOf(0))
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [style.color.withValues(alpha: style.density * 0.75), style.color.withValues(alpha: style.density * 0.1)],
          ).createShader(plot),
      );
    }
    final stroke = Paint()
      ..color = style.color.withValues(alpha: style.type == _ChartType.line ? style.density : 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = style.lineStyle == _LineStyle.dotted ? StrokeCap.round : StrokeCap.butt;
    _strokePath(canvas, path, stroke, style.lineStyle, style.strokeWidth);

    for (var i = 0; i < pts.length; i++) {
      final c = Offset(xOf(i), yOf(pts[i].value));
      canvas.drawCircle(c, style.strokeWidth + 2.5, Paint()..color = Colors.white);
      canvas.drawCircle(c, style.strokeWidth + 2.5, Paint()
        ..color = style.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      if (style.showValues) _value(canvas, pts[i].value, c.translate(0, pts[i].value >= 0 ? -10 : 10), above: pts[i].value >= 0);
    }
  }

  void _strokePath(Canvas canvas, Path path, Paint paint, _LineStyle s, double w) {
    final pattern = s.pattern(w);
    if (pattern == null) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final m in path.computeMetrics()) {
      var d = 0.0, i = 0;
      var draw = true;
      while (d < m.length) {
        final len = pattern[i % pattern.length];
        if (draw) canvas.drawPath(m.extractPath(d, math.min(d + len, m.length)), paint);
        d += len;
        i++;
        draw = !draw;
      }
    }
  }

  void _value(Canvas canvas, double v, Offset at, {required bool above}) =>
      _text(canvas, (v >= 0 ? '+' : '') + v.toStringAsFixed(2), at, 10, _inkStrong, FontWeight.w700,
          align: _A.center, below: !above);

  void _text(Canvas canvas, String s, Offset at, double size, Color color, FontWeight weight,
      {_A align = _A.left, bool below = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) { _A.left => at.dx, _A.center => at.dx - tp.width / 2, _A.right => at.dx - tp.width };
    final dy = below ? at.dy : at.dy - tp.height;
    tp.paint(canvas, Offset(dx, align == _A.right ? at.dy - tp.height / 2 : dy));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}

enum _A { left, center, right }

class TemperatureCanvasChart extends StatefulWidget {
  const TemperatureCanvasChart({super.key});

  @override
  State<TemperatureCanvasChart> createState() => _TemperatureCanvasChartState();
}

class _TemperatureCanvasChartState extends State<TemperatureCanvasChart> {
  static const double _canvasHeight = 340;

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

  _ChartType _type = _ChartType.bars;
  _LineStyle _lineStyle = _LineStyle.solid;
  Color _color = _palette.first.$2;
  double _density = 0.85;
  double _strokeWidth = 2;
  bool _showValues = true;

  _Series get _cur => _series[_which];

  @override
  void initState() {
    super.initState();
    _controller = CanvasController(_onExported);
    _controller.setOnStateChanged((isDrawing, isErasing) {
      if (mounted) {
        setState(() {
          _drawing = isDrawing;
          _erasing = isErasing;
        });
      }
    });
    _count = _clampInt(_cur.points.length, 3, 8);
  }

  Future<void> _onExported(dynamic png) async {
    final bytes = png as Uint8List;
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final name = 'temperature-anomaly-$stamp.png';
    final saved = await downloadPng(bytes, name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved
          ? 'Chart saved as $name'
          : 'Chart exported (${bytes.length} bytes), but automatic saving is only available in the web build'),
    ));
  }

  void _setStyle(VoidCallback change) {
    setState(change);
    _plot();
  }

  void _plot() {
    if (_width <= 0) return;
    _controller.clearAll();
    final pts = _cur.points.take(_count).toList();
    final style = _ChartStyle(_type, _lineStyle, _color, _density, _strokeWidth, _showValues);
    final w = _width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.addComponent(
        SizedBox(
          width: w,
          height: _canvasHeight,
          child: IgnorePointer(child: CustomPaint(painter: _ChartPainter(pts, style))),
        ),
        Offset.zero,
      );
    });
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(s, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _inkSoft)),
      );

  bool? _dark;
  void _syncTheme(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _inkStrong = dark ? Colors.white : Colors.black87;
    _inkSoft = dark ? Colors.white70 : Colors.black54;
    _gridInk = dark ? Colors.white24 : Colors.black12;
    if (_dark != null && _dark != dark) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _plot();
      });
    }
    _dark = dark;
  }

  @override
  Widget build(BuildContext context) {
    _syncTheme(context);
    final total = _cur.points.length;
    const minCount = 3;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Data set'),
      Wrap(spacing: 8, children: [
        for (var i = 0; i < _series.length; i++)
          ChoiceChip(
            label: Text(_series[i].label),
            selected: _which == i,
            onSelected: (_) {
              _which = i;
              _setStyle(() => _count = _clampInt(_count, minCount, _series[i].points.length));
            },
          ),
      ]),
      if (total > minCount)
        Row(children: [
          Text('Data points: $_count of $total', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Slider(
              min: minCount.toDouble(),
              max: total.toDouble(),
              divisions: total - minCount,
              value: _clampInt(_count, minCount, total).toDouble(),
              label: '$_count',
              onChanged: (v) => _setStyle(() => _count = v.round()),
            ),
          ),
        ]),
      _label('Chart type'),
      Wrap(spacing: 8, children: [
        for (final t in _ChartType.values)
          ChoiceChip(label: Text(t.label), selected: _type == t, onSelected: (_) => _setStyle(() => _type = t)),
      ]),
      _label(_type == _ChartType.bars ? 'Outline style' : 'Line style'),
      Wrap(spacing: 8, children: [
        for (final s in _LineStyle.values)
          ChoiceChip(label: Text(s.label), selected: _lineStyle == s, onSelected: (_) => _setStyle(() => _lineStyle = s)),
      ]),
      _label('Color'),
      Wrap(spacing: 10, children: [
        for (final (name, c) in _palette)
          Tooltip(
            message: name,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _setStyle(() => _color = c),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: _color == c ? Colors.black : Colors.black26, width: _color == c ? 3 : 1),
                ),
              ),
            ),
          ),
      ]),
      Row(children: [
        SizedBox(width: 150, child: Text('Color density: ${(_density * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(
          child: Slider(
            min: 0.2,
            max: 1.0,
            divisions: 16,
            value: _density,
            label: '${(_density * 100).round()}%',
            onChanged: (v) => _setStyle(() => _density = v),
          ),
        ),
      ]),
      Row(children: [
          SizedBox(width: 150, child: Text('Line width: ${_strokeWidth.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: Slider(
              min: 1,
              max: 6,
              divisions: 10,
              value: _strokeWidth,
              label: _strokeWidth.toStringAsFixed(1),
              onChanged: (v) => _setStyle(() => _strokeWidth = v),
            ),
          ),
        ]),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Show values'),
        value: _showValues,
        onChanged: (v) => _setStyle(() => _showValues = v),
      ),
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
        IconButton(tooltip: 'Export PNG (saved automatically)', icon: const Icon(Icons.download), onPressed: _controller.exportCanvas),
      ]),
      LayoutBuilder(builder: (context, box) {
        if ((box.maxWidth - _width).abs() > 1) {
          _width = box.maxWidth;
          WidgetsBinding.instance.addPostFrameCallback((_) => _plot());
        }
        return Container(
          height: _canvasHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _dark == true ? const Color(0xE61B2028) : Colors.white.withValues(alpha: 0.70),
            border: Border.all(color: _dark == true ? Colors.white24 : Colors.black12),
          ),
          child: CanvasWidget(controller: _controller),
        );
      }),
    ]);
  }
}