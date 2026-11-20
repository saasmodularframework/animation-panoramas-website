import 'dart:math' as math;

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../l10n/app_strings.dart';
import '../services/db_service.dart';
import '../widgets/page_shell.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, Object?>> _rows = [];
  bool _busy = true;

  final Map<int, Map<String, Object?>> _known = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var r = <Map<String, Object?>>[];
    try {
      r = await Db.notes();
    } catch (e) {
      debugPrint('Notes DB error: $e');
    }
    for (final n in r) {
      _known[n['id'] as int] = n;
    }
    if (mounted) setState(() {
          _rows = r;
          _busy = false;
        });
  }

  Future<void> _add() async {
    final t = TextEditingController(), b = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('notes')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: t, decoration: InputDecoration(labelText: context.tr('title'))),
          TextField(controller: b, minLines: 3, maxLines: 5, decoration: InputDecoration(labelText: context.tr('body'))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('✕')), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('save')))],
      ),
    );
    if (ok == true && t.text.trim().isNotEmpty) {
      try {
        await Db.addNote(t.text.trim(), b.text.trim());
      } catch (e) {
        debugPrint('Add note error: $e');
      }
      _load();
    }
  }

  static const _fills = <Color>[
    Color(0xFFFFF1A8), // yellow
    Color(0xFFF9C9DB), // pink
    Color(0xFFBFE3F6), // blue
    Color(0xFFCDEBC3), // green
    Color(0xFFDCD0F2), // lavender
    Color(0xFFFFD8B0), // orange
    Color(0xFFBFEBE0), // mint
  ];
  static const _ink = Color(0xFF263238);

  int _columnsFor(double width) => width < 480 ? 2 : (width < 800 ? 3 : 4);

  List<(int, String)> _gridRows(int cols) => [
        for (var i = 0; i < _rows.length; i += cols)
          (i ~/ cols, _rows.sublist(i, math.min(i + cols, _rows.length)).map((n) => n['id'] as int).join(',')),
      ];

  Widget _animated(Animation<double> animation, Widget child) => SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: FadeTransition(opacity: animation, child: child),
      );

  Widget _gridRow((int, String) row, int cols, String lang, {bool interactive = true}) {
    final ids = row.$2.isEmpty ? <int>[] : row.$2.split(',').map(int.parse).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var c = 0; c < cols; c++) ...[
            if (c > 0) const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (current, previous) =>
                    Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child)),
                child: c < ids.length && _known[ids[c]] != null
                    ? _noteCard(_known[ids[c]]!, lang, interactive: interactive)
                    : SizedBox.shrink(key: ValueKey('empty$c')),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _noteCard(Map<String, Object?> n, String lang, {bool interactive = true}) {
    final id = n['id'] as int;
    final when = DateTime.fromMillisecondsSinceEpoch(n['created'] as int);
    final fill = _fills[id % _fills.length];
    return Card(
      key: ValueKey(id),
      margin: EdgeInsets.zero,
      color: fill,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Color.lerp(fill, Colors.black, 0.12)!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(n['title'] as String,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
            ),
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20, color: _ink),
              onPressed: !interactive
                  ? null
                  : () async {
                      try {
                        await Db.deleteNote(id);
                      } catch (e) {
                        debugPrint('Delete note error: $e');
                      }
                      _load();
                    },
            ),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text('${n['body']}', maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, height: 1.3)),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.schedule, size: 12, color: Colors.black54),
            const SizedBox(width: 4),
            Text(timeago.format(when, locale: lang), style: const TextStyle(fontSize: 11, color: Colors.black54)), // timeago on every note
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return PageShell(
      slug: 'notes',
      title: context.tr('notes'),
      crumbs: [context.tr('notes')],
      busy: _busy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 80), child: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: Text(context.tr('add')))),
        body: LayoutBuilder(builder: (context, box) {
          final cols = _columnsFor(box.maxWidth);

          return ImplicitlyAnimatedList<(int, String)>(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 160),
            items: _gridRows(cols),
            areItemsTheSame: (a, b) => a.$1 == b.$1,
            insertDuration: const Duration(milliseconds: 350),
            removeDuration: const Duration(milliseconds: 300),
            itemBuilder: (context, animation, row, i) => _animated(animation, _gridRow(row, cols, lang)),
            updateItemBuilder: (context, animation, row) => _gridRow(row, cols, lang),
            removeItemBuilder: (context, animation, row) => _animated(animation, _gridRow(row, cols, lang, interactive: false)),
          );
        }),
      ),
    );
  }
}
