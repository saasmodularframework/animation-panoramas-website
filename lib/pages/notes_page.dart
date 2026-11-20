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

  Widget _animated(Animation<double> animation, Widget child) => SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: FadeTransition(opacity: animation, child: child),
      );

  Widget _card(Map<String, Object?> n, String lang, {bool interactive = true}) {
    final when = DateTime.fromMillisecondsSinceEpoch(n['created'] as int);
    return Card(
      child: ListTile(
        title: Text(n['title'] as String),
        subtitle: Text('${n['body']}\n${timeago.format(when, locale: lang)}'), // timeago on every note
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: !interactive
              ? null
              : () async {
                  try {
                    await Db.deleteNote(n['id'] as int);
                  } catch (e) {
                    debugPrint('Delete note error: $e');
                  }
                  _load();
                },
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
        floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 80), child: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: Text(context.tr('add')))),
        // Rows are diffed by note id, so adding / deleting animates automatically.
        body: ImplicitlyAnimatedList<Map<String, Object?>>(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 160),
          items: _rows,
          areItemsTheSame: (a, b) => a['id'] == b['id'],
          insertDuration: const Duration(milliseconds: 350),
          removeDuration: const Duration(milliseconds: 300),
          itemBuilder: (context, animation, n, i) => _animated(animation, _card(n, lang)),
          removeItemBuilder: (context, animation, n) => _animated(animation, _card(n, lang, interactive: false)),
        ),
      ),
    );
  }
}

