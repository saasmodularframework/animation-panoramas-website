import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../services/db_service.dart';
import '../widgets/page_shell.dart';
import 'services_agenda_pages.dart' show kServices;

typedef Row_ = Map<String, dynamic>;

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});
  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  List<Row_> rows = [];
  bool busy = true, sample = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await Db.bookings();
    var r = <Row_>[
      for (final x in b)
        {
          'ms': x['whenMs'] as int,
          'service': x['service'] as String,
          'note': x['note'] as String,
        }
    ];
    if (r.length < 3) {
      sample = true;
      final rnd = Random(7);
      final base = DateTime.now();
      r = [
        for (int i = 0; i < 12; i++)
          {
            'ms': DateTime(base.year, base.month, base.day + i ~/ 2, 8 + rnd.nextInt(10), 0).millisecondsSinceEpoch,
            'service': kServices[rnd.nextInt(kServices.length)],
            'note': List.generate(1 + rnd.nextInt(12), (_) => ['bug', 'login', 'ui', 'api', 'release', 'test'][rnd.nextInt(6)]).join(' '),
          }
      ];
    }
    r.sort((a, b) => (a['ms'] as int).compareTo(b['ms'] as int));
    final days = <String>[];
    for (final x in r) {
      final d = DateTime.fromMillisecondsSinceEpoch(x['ms'] as int);
      x['day'] = DateFormat('dd.MM').format(d);
      x['hour'] = d.hour + d.minute / 60.0;
      x['len'] = max((x['note'] as String).length, 1);
      if (!days.contains(x['day'])) days.add(x['day'] as String);
      x['dayIdx'] = days.indexOf(x['day'] as String);
    }
    if (mounted) setState(() {
          rows = r;
          busy = false;
        });
  }

  List<String> get _days => rows.map((e) => e['day'] as String).toSet().toList();
  List<String> get _svcs => rows.map((e) => e['service'] as String).toSet().toList();

  List<Row_> get _perDay => [
        for (final d in _days)
          {
            'day': d,
            'hour': rows.where((r) => r['day'] == d).map((r) => r['hour'] as double).reduce((a, b) => a + b) /
                rows.where((r) => r['day'] == d).length,
            'count': rows.where((r) => r['day'] == d).length,
            'len': rows.where((r) => r['day'] == d).map((r) => r['len'] as int).reduce((a, b) => a + b),
          }
      ];

  List<Row_> get _hist {
    const edges = [0, 6, 9, 12, 15, 18, 21, 24];
    return [
      for (int i = 0; i < edges.length - 1; i++)
        {
          'bucket': '${edges[i]}-${edges[i + 1]}',
          'count': rows.where((r) => (r['hour'] as double) >= edges[i] && (r['hour'] as double) < edges[i + 1]).length,
        }
    ];
  }

  List<Row_> get _stack => [
        for (final d in _days)
          for (final s in _svcs)
            {
              'day': d,
              'service': s,
              'len': rows.where((r) => r['day'] == d && r['service'] == s).fold<int>(0, (a, r) => a + (r['len'] as int)),
            }
      ];

  List<Row_> get _pie {
    final total = rows.length;
    return [
      for (final s in _svcs) {'service': s, 'percent': rows.where((r) => r['service'] == s).length / total}
    ];
  }

  Widget _card(String t, Widget c, {double h = 260}) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(height: h, child: c),
          ]),
        ),
      );

  Variable<Row_, String> _v(String k) => Variable(accessor: (Row_ m) => m[k] as String);
  Variable<Row_, num> _n(String k, {double? min, double? max}) =>
      Variable(accessor: (Row_ m) => m[k] as num, scale: LinearScale(min: min, max: max));

  @override
  Widget build(BuildContext context) {
    final axes = [Defaults.horizontalAxis, Defaults.verticalAxis];
    final maxLen = rows.isEmpty ? 1.0 : rows.map((r) => (r['len'] as int).toDouble()).reduce(max);
    return PageShell(
      slug: 'chart',
      title: context.tr('chart'),
      crumbs: [context.tr('services'), context.tr('chart')],
      busy: busy,
      child: rows.isEmpty
          ? const SizedBox()
          : ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 100), children: [
              if (sample) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Sample data shown – fewer than 3 bookings saved.', style: TextStyle(fontStyle: FontStyle.italic))),
              _card('1. Line graph – average time per day', Chart<Row_>(data: _perDay, variables: {'day': _v('day'), 'hour': _n('hour', min: 0, max: 24)}, marks: [LineMark(shape: ShapeEncode(value: BasicLineShape(smooth: true)))], axes: axes)),
              _card('2. Histogram – bookings by time of day', Chart<Row_>(data: _hist, variables: {'bucket': _v('bucket'), 'count': _n('count', min: 0)}, marks: [IntervalMark()], axes: axes)),
              _card(
                '3. Stacked line / area – note length per service',
                Chart<Row_>(
                  data: _stack,
                  variables: {'day': _v('day'), 'len': _n('len', min: 0), 'service': _v('service')},
                  marks: [
                    AreaMark(
                      position: Varset('day') * Varset('len') / Varset('service'),
                      color: ColorEncode(variable: 'service', values: Defaults.colors10),
                      modifiers: [StackModifier()],
                    ),
                    LineMark(
                      position: Varset('day') * Varset('len') / Varset('service'),
                      color: ColorEncode(variable: 'service', values: Defaults.colors10),
                      modifiers: [StackModifier()],
                    ),
                  ],
                  axes: axes,
                ),
              ),
              _card(
                '4. Bubble – time × day, size = note length',
                Chart<Row_>(
                  data: rows,
                  variables: {'hour': _n('hour', min: 0, max: 24), 'dayIdx': _n('dayIdx', min: -1), 'len': _n('len'), 'service': _v('service')},
                  marks: [
                    PointMark(
                      position: Varset('hour') * Varset('dayIdx'),
                      size: SizeEncode(variable: 'len', values: [8, 36]),
                      color: ColorEncode(variable: 'service', values: Defaults.colors10.map((c) => c.withAlpha(150)).toList()),
                    )
                  ],
                  axes: axes,
                ),
              ),
              _card('5. 3D columns – bookings per day', CustomPaint(painter: _Columns3D(_perDay.map((e) => (e['count'] as int).toDouble()).toList(), _days, Theme.of(context).colorScheme.primary), child: const SizedBox.expand())),
              _card(
                '6. Pie – share per service',
                Chart<Row_>(
                  data: _pie,
                  variables: {'service': _v('service'), 'percent': _n('percent', min: 0)},
                  marks: [
                    IntervalMark(
                      position: Varset('percent') / Varset('service'),
                      color: ColorEncode(variable: 'service', values: Defaults.colors10),
                      modifiers: [StackModifier()],
                    )
                  ],
                  coord: PolarCoord(transposed: true, dimCount: 1),
                ),
              ),
              _card('7. Word cloud – from your notes', _WordCloud(rows.map((r) => r['note'] as String).join(' ')), h: 200),
              _card('8. Flowchart – latest booking', _Flow(rows.last), h: 120),
              _card(
                '9. Multi-axis – time (blue, left) vs note length (orange, right)',
                Stack(children: [
                  Chart<Row_>(
                    padding: (_) => const EdgeInsets.fromLTRB(40, 10, 44, 30),
                    data: _perDay,
                    variables: {'day': _v('day'), 'hour': _n('hour', min: 0, max: 24)},
                    marks: [LineMark(color: ColorEncode(value: Colors.blue), shape: ShapeEncode(value: BasicLineShape(smooth: true)))],
                    axes: axes,
                  ),
                  Chart<Row_>(
                    padding: (_) => const EdgeInsets.fromLTRB(40, 10, 44, 30),
                    data: _perDay,
                    variables: {'day': _v('day'), 'len': _n('len', min: 0, max: maxLen * 3.0)},
                    marks: [LineMark(color: ColorEncode(value: Colors.orange), shape: ShapeEncode(value: BasicLineShape(smooth: true)))],
                    axes: const [],
                  ),
                  Positioned(right: 0, top: 6, child: Text('${(maxLen * 3).round()}', style: const TextStyle(color: Colors.orange, fontSize: 10))),
                  const Positioned(right: 0, bottom: 28, child: Text('0', style: TextStyle(color: Colors.orange, fontSize: 10))),
                ]),
              ),
              _card('10. Scatter – time vs note length', Chart<Row_>(data: rows, variables: {'hour': _n('hour', min: 0, max: 24), 'len': _n('len', min: 0)}, marks: [PointMark()], axes: axes)),
            ]),
    );
  }
}

class _Columns3D extends CustomPainter {
  final List<double> v;
  final List<String> labels;
  final Color color;
  _Columns3D(this.v, this.labels, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    if (v.isEmpty) return;
    final mx = v.reduce(max);
    final slot = s.width / v.length, w = slot * 0.5, d = w * 0.35;
    for (int i = 0; i < v.length; i++) {
      final h = (v[i] / mx) * (s.height - 40 - d), x = i * slot + slot * 0.2, y = s.height - 20;
      final front = Path()..addRect(Rect.fromLTWH(x, y - h, w, h));
      final top = Path()..moveTo(x, y - h)..lineTo(x + d, y - h - d)..lineTo(x + w + d, y - h - d)..lineTo(x + w, y - h)..close();
      final side = Path()..moveTo(x + w, y - h)..lineTo(x + w + d, y - h - d)..lineTo(x + w + d, y - d)..lineTo(x + w, y)..close();
      canvas.drawPath(front, Paint()..color = color);
      canvas.drawPath(top, Paint()..color = Color.lerp(color, Colors.white, 0.4)!);
      canvas.drawPath(side, Paint()..color = Color.lerp(color, Colors.black, 0.35)!);
      final tp = TextPainter(text: TextSpan(text: labels[i], style: const TextStyle(fontSize: 9, color: Colors.grey)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x, s.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _Columns3D o) => o.v != v;
}

class _WordCloud extends StatelessWidget {
  final String text;
  const _WordCloud(this.text);
  @override
  Widget build(BuildContext context) {
    final freq = <String, int>{};
    for (final w in text.toLowerCase().split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))) {
      if (w.length > 2) freq[w] = (freq[w] ?? 0) + 1;
    }
    final entries = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = Defaults.colors10;
    return Center(
      child: Wrap(spacing: 10, runSpacing: 4, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (int i = 0; i < min(entries.length, 40); i++)
          RotatedBox(
            quarterTurns: i % 5 == 4 ? 1 : 0,
            child: Text(entries[i].key, style: TextStyle(fontSize: 12.0 + entries[i].value * 5, fontWeight: FontWeight.bold, color: colors[i % colors.length])),
          ),
      ]),
    );
  }
}

class _Flow extends StatelessWidget {
  final Row_ r;
  const _Flow(this.r);
  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(r['ms'] as int);
    final steps = ['Service\n${r['service']}', 'Date\n${DateFormat('dd.MM.yyyy').format(d)}', 'Time\n${DateFormat.Hm().format(d)}', 'Notes\n${(r['note'] as String).length} chars', 'Chart'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (int i = 0; i < steps.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary), borderRadius: BorderRadius.circular(i == steps.length - 1 ? 30 : 8)),
            child: Text(steps[i], textAlign: TextAlign.center),
          ),
          if (i < steps.length - 1) const Icon(Icons.arrow_right_alt, size: 32),
        ]
      ]),
    );
  }
}
