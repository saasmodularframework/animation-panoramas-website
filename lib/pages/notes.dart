import 'dart:math' as math;

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropdown_alert/alert_controller.dart';
import 'package:flutter_dropdown_alert/model/data_alert.dart';
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
  int? _highlightedId;

  final Map<int, Map<String, Object?>> _known = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? highlightId}) async {
    var r = <Map<String, Object?>>[];
    try {
      r = await Db.notes();
    } catch (e) {
      debugPrint('Notes DB error: $e');
    }
    for (final n in r) {
      final id = n['id'] as int;
      _known[id] = n;
    }
    if (!mounted) return;
    setState(() {
      _rows = r;
      _busy = false;
      _highlightedId = highlightId;
    });

    if (highlightId != null) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _highlightedId == highlightId) {
          setState(() => _highlightedId = null);
        }
      });
    }
  }

  Future<Map<String, String>?> _editDialog({
    required String dialogTitle,
    String initialTitle = '',
    String initialBody = '',
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    final bodyCtrl = TextEditingController(text: initialBody);

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(labelText: context.tr('title')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(labelText: context.tr('body')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('✕'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.tr('save')),
            ),
          ],
        ),
      );

      if (saved != true || titleCtrl.text.trim().isEmpty) return null;
      return {
        'title': titleCtrl.text.trim(),
        'body': bodyCtrl.text.trim(),
      };
    } finally {
      titleCtrl.dispose();
      bodyCtrl.dispose();
    }
  }

  Future<void> _add() async {
    final result = await _editDialog(dialogTitle: context.tr('notes'));
    if (result == null) return;

    final title = result['title'] as String;
    final body = result['body'] as String;

    try {
      await Db.addNote(title, body);
      final fresh = await Db.notes();
      int? newestId;
      for (final n in fresh) {
        final id = n['id'] as int;
        if (!_known.containsKey(id)) {
          newestId = id;
          break;
        }
      }
      await _load(highlightId: newestId);
      AlertController.show('Note created', '"$title" was added to your notes.', TypeAlert.success);
    } catch (e) {
      debugPrint('Add note error: $e');
      AlertController.show('Could not create note', 'Something went wrong while saving. Please try again.', TypeAlert.error);
      await _load();
    }
  }

  Future<void> _edit(Map<String, Object?> note) async {
    final id = note['id'] as int;
    final result = await _editDialog(
      dialogTitle: context.tr('edit'),
      initialTitle: '${note['title'] ?? ''}',
      initialBody: '${note['body'] ?? ''}',
    );
    if (result == null) return;

    final updatedTitle = result['title'] as String;
    final updatedBody = result['body'] as String;

    final updated = <String, Object?>{
      ...note,
      'title': updatedTitle,
      'body': updatedBody,
    };
    _known[id] = updated;
    setState(() {
      _rows = [
        for (final r in _rows) (r['id'] as int) == id ? updated : r,
      ];
      _highlightedId = id;
    });

    try {
      await Db.updateNote(id, updatedTitle, updatedBody);
      AlertController.show('Note updated', '"$updatedTitle" was saved with your changes.', TypeAlert.success);
    } catch (e) {
      debugPrint('Update note error: $e');
      AlertController.show('Could not update note', 'Your changes were not saved. Please try again.', TypeAlert.error);
    }

    await _load(highlightId: id);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _highlightedId == id) {
        setState(() => _highlightedId = null);
      }
    });
  }

  Future<void> _delete(int id) async {
    final removedTitle = '${_known[id]?['title'] ?? ''}';
    try {
      await Db.deleteNote(id);
      AlertController.show('Note deleted', removedTitle.isEmpty ? 'The note was removed.' : '"$removedTitle" was removed.', TypeAlert.warning);
    } catch (e) {
      debugPrint('Delete note error: $e');
      AlertController.show('Could not delete note', 'The note was not removed. Please try again.', TypeAlert.error);
    }
    await _load();
  }

  static const _fills = <Color>[
    Color(0xFFDADFE3),
    Color(0xFFC9D3DA),
    Color(0xFFBFD3E6),
    Color(0xFFD7CCC8),
    Color(0xFFCFC3B8),
    Color(0xFFB8C7D9),
    Color(0xFFC4C4BE),
  ];
  static const _ink = Color(0xFF263238);

  int _columnsFor(double width) => width < 480 ? 2 : (width < 800 ? 3 : 4);

  List<(int, String)> _gridRows(int cols) => [
        for (var i = 0; i < _rows.length; i += cols)
          (
            i ~/ cols,
            _rows
                .sublist(i, math.min(i + cols, _rows.length))
                .map((n) => n['id'] as int)
                .join(','),
          ),
      ];

  Widget _animated(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }

  Widget _gridRow((int, String) row, int cols, String lang, {bool interactive = true}) {
    final ids = row.$2.isEmpty ? <int>[] : row.$2.split(',').map(int.parse).toList();
    return Padding(
      key: ValueKey('row_${row.$1}_${row.$2}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var c = 0; c < cols; c++) ...[
              if (c > 0) const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, if (current != null) current],
                  ),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: c < ids.length && _known[ids[c]] != null
                      ? _noteCard(_known[ids[c]]!, lang, interactive: interactive)
                      : SizedBox(key: ValueKey('empty_${row.$1}_$c')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noteCard(Map<String, Object?> n, String lang, {bool interactive = true}) {
    final id = n['id'] as int;
    final when = DateTime.fromMillisecondsSinceEpoch(n['created'] as int);
    final fill = _fills[id % _fills.length];
    final highlighted = _highlightedId == id;

    return AnimatedContainer(
      key: ValueKey(id),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.55),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: fill,
        surfaceTintColor: Colors.transparent,
        elevation: highlighted ? 5 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highlighted
                ? Colors.amber.shade700
                : Color.lerp(fill, Colors.black, 0.12)!,
            width: highlighted ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: interactive ? () => _edit(n) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, if (current != null) current],
                        ),
                        child: Text(
                          '${n['title'] ?? ''}',
                          key: ValueKey('title_$id\_${n['title']}'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _ink,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('edit'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 19, color: _ink),
                      onPressed: !interactive ? null : () => _edit(n),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 19, color: _ink),
                      onPressed: !interactive ? null : () => _delete(id),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topLeft,
                        children: [...previous, if (current != null) current],
                      ),
                      child: Text(
                        '${n['body'] ?? ''}',
                        key: ValueKey('body_$id\_${n['body']}'),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _ink, height: 1.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 12, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      timeago.format(when, locale: lang),
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton.extended(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text(context.tr('add')),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, box) {
            final cols = _columnsFor(box.maxWidth);
            return ImplicitlyAnimatedList<(int, String)>(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 160),
              items: _gridRows(cols),
              areItemsTheSame: (a, b) => a.$1 == b.$1 && a.$2 == b.$2,
              insertDuration: const Duration(milliseconds: 350),
              removeDuration: const Duration(milliseconds: 300),
              itemBuilder: (context, animation, row, i) =>
                  _animated(animation, _gridRow(row, cols, lang)),
              updateItemBuilder: (context, animation, row) =>
                  _gridRow(row, cols, lang),
              removeItemBuilder: (context, animation, row) =>
                  _animated(animation, _gridRow(row, cols, lang, interactive: false)),
            );
          },
        ),
      ),
    );
  }
}