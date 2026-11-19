import 'package:flutter/material.dart';

Color scale(double t, Color a, Color b, [Color? mid]) {
  t = t.clamp(0.0, 1.0);
  if (mid == null) return Color.lerp(a, b, t)!;
  return t < 0.5 ? Color.lerp(a, mid, t * 2)! : Color.lerp(mid, b, (t - 0.5) * 2)!;
}

Color onColor(Color c) => c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

class DataPageBody extends StatelessWidget {
  const DataPageBody({
    super.key,
    required this.title,
    required this.variable,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final String variable;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Color.lerp(color, Colors.black, 0.35)!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, dark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(variable,
                        style: const TextStyle(fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.title,
    required this.color,
    required this.child,
    this.note,
    this.sample = false,
  });

  final String title;
  final Color color;
  final Widget child;
  final String? note;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    return Card(

      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: onColor(color), fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (sample)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: const Text('sample values',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(8), child: child),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(note!,
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
            ),
        ],
      ),
    );
  }
}

Widget gridTable({
  required List<String> headers,
  required List<List<Widget>> rows,
  required Color headerColor,
  Color? zebra,
  List<double>? flex,
}) {
  return Table(
    defaultVerticalAlignment: TableCellVerticalAlignment.fill,
    border: TableBorder.all(color: Colors.white, width: 1.5),
    columnWidths: {
      for (var i = 0; i < headers.length; i++) i: FlexColumnWidth(flex != null ? flex[i] : 1),
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: headerColor),
        children: [
          for (final h in headers)
            Container(
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              child: Text(h,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: onColor(headerColor), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
      for (var i = 0; i < rows.length; i++)
        TableRow(
          decoration: BoxDecoration(
              color: i.isEven ? (zebra ?? Colors.grey.shade100) : Colors.white),
          children: rows[i],
        ),
    ],
  );
}

Widget cell(String text,
    {Color? bg, Color? fg, bool bold = false, bool left = false}) {
  return Container(
    color: bg,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    alignment: left ? Alignment.centerLeft : Alignment.center,
    child: Text(
      text,
      textAlign: left ? TextAlign.left : TextAlign.center,
      style: TextStyle(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: fg ?? (bg != null ? onColor(bg) : Colors.black87),
      ),
    ),
  );
}

Widget barCell(double value, double maxAbs, Color color, String label) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (value.abs() / maxAbs).clamp(0.0, 1.0),
            minHeight: 10,
            color: color,
            backgroundColor: color.withAlpha(40),
          ),
        ),
      ],
    ),
  );
}

Widget pill(String text, Color bg) {
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(color: onColor(bg), fontWeight: FontWeight.bold, fontSize: 12)),
    ),
  );
}
