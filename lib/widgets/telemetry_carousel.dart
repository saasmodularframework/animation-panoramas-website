import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../data/telemetry_sections.dart';
import '../pages_registry.dart';

class ClimateCarousel extends StatefulWidget {
  const ClimateCarousel({super.key, required this.slug, required this.title, required this.icon, required this.color});
  final String slug, title;
  final IconData icon;
  final Color color;

  @override
  State<ClimateCarousel> createState() => _ClimateCarouselState();
}

class _ClimateCarouselState extends State<ClimateCarousel> {
  late List<DataSection> _sections = fallbackSections(widget.slug);

  @override
  void initState() {
    super.initState();

    loadSections(widget.slug).then((s) {
      if (mounted) setState(() => _sections = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => openPage(context, widget.slug),
          child: Container(
            color: widget.color,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const Text('Open page', style: TextStyle(color: Colors.white70)),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ]),
          ),
        ),
        FlutterCarousel(
          key: ValueKey('${widget.slug}-${_sections.map((s) => s.badge).join()}'),
          height: 500,
          indicator: CarouselIndicator(
            painter: CircularWaveIndicator(style: SlideIndicatorStyle(activeColor: widget.color)),
            placement: CarouselIndicatorPlacement.below,
          ),
          items: [for (final s in _sections) _Slide(section: s, slug: widget.slug, color: widget.color)],
        ),
      ]),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.section, required this.slug, required this.color});
  final DataSection section;
  final String slug;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rows = section.shown;
    return InkWell(
      onTap: () => openPage(context, slug),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(section.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Chip(
              label: Text(section.badge, style: const TextStyle(fontSize: 11)),
              backgroundColor: section.badge == 'live' ? Colors.green.shade100 : Colors.grey.shade200,
              visualDensity: VisualDensity.compact,
            ),
          ]),
   
          IgnorePointer(
            child: SizedBox(
              height: 330,
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 40,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 48,
                    columns: [for (final c in section.columns) DataColumn(label: Text(c))],
                    rows: [
                      for (final r in rows) DataRow(cells: [for (final v in r) DataCell(Text(v))]),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (section.truncated || section.note != null)
            Text(
              [
                if (section.truncated) 'Showing ${rows.length} of ${section.rows.length} rows.',
                if (section.note != null) section.note!,
              ].join(' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
            ),
        ]),
      ),
    );
  }
}
