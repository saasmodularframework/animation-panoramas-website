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
    final r = await Db.notes();
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
      await Db.addNote(t.text.trim(), b.text.trim());
      _load();
    }
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
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 160),
          itemCount: _rows.length,
          itemBuilder: (_, i) {
            final n = _rows[i];
            final when = DateTime.fromMillisecondsSinceEpoch(n['created'] as int);
            return Card(
              child: ListTile(
                title: Text(n['title'] as String),
                subtitle: Text('${n['body']}\n${timeago.format(when, locale: lang)}'), // timeago on every note
                isThreeLine: true,
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                  await Db.deleteNote(n['id'] as int);
                  _load();
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}
