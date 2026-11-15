import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/app_strings.dart';
import '../pages_registry.dart';
import '../services/db_service.dart';
import '../services/rss_pdf_service.dart';
import '../widgets/page_shell.dart';
import '../widgets/textured_button.dart';

class PdfLibraryPage extends StatelessWidget {
  const PdfLibraryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'pdf-library',
      title: context.tr('pdf'),
      crumbs: [context.tr('pdf')],
      child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 100), children: [
        for (final p in appPages)
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(p.title),
              subtitle: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Wrap(children: [
                IconButton(
                  tooltip: 'Preview / print',
                  icon: const Icon(Icons.visibility),
                  onPressed: () => Printing.layoutPdf(onLayout: (_) => PdfService.build(p), name: '${p.slug}.pdf'),
                ),
                IconButton(
                  tooltip: 'Share / download',
                  icon: const Icon(Icons.download),
                  onPressed: () async => Printing.sharePdf(bytes: await PdfService.build(p), filename: '${p.slug}.pdf'),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _n = TextEditingController(), _p = TextEditingController();
  bool _busy = true, _first = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    Db.hasAdmin().then((h) => mounted ? setState(() {
          _first = !h; 
          _busy = false;
        }) : null);
  }

  Future<void> _submit() async {
    if (_n.text.trim().isEmpty || _p.text.length < 6) {
      setState(() => _err = 'Name required, password min 6 chars');
      return;
    }
    setState(() => _busy = true);
    if (_first) await Db.createAdmin(_n.text.trim(), _p.text);
    final ok = await Db.verifyAdmin(_n.text.trim(), _p.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _err = ok ? null : 'Wrong name or password';
    });
    if (ok) Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(builder: (_) => const AdminPanelPage()));
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'admin',
      title: context.tr('admin'),
      crumbs: [context.tr('contact'), context.tr('admin')],
      busy: _busy,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_first) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('No admin yet – these credentials will create the first one.')),
              TextField(controller: _n, decoration: InputDecoration(labelText: context.tr('name'))),
              TextField(controller: _p, obscureText: true, decoration: InputDecoration(labelText: context.tr('password')), onSubmitted: (_) => _submit()),
              if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 16),
              TexturedButton(label: context.tr('login'), icon: Icons.login, onPressed: _submit),
            ]),
          ),
        ),
      ),
    );
  }
}

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});
  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  Future<List<List<Map<String, Object?>>>> _load() async => [await Db.bookings(), await Db.notes(), await Db.admins()];

  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'admin',
      title: '${context.tr('admin')} panel',
      crumbs: [context.tr('admin')],
      child: FutureBuilder<List<List<Map<String, Object?>>>>(
        future: _load(),
        builder: (c, s) {
          if (!s.hasData) return const SizedBox();
          final d = s.data!;
          return DefaultTabController(
            length: 3,
            child: Column(children: [
              TabBar(tabs: [Tab(text: 'Bookings (${d[0].length})'), Tab(text: 'Notes (${d[1].length})'), Tab(text: 'Admins (${d[2].length})')]),
              Expanded(
  
                child: TabBarView(children: [
                  _list(d[0], (r) => '${r['service']}  ·  ${DateTime.fromMillisecondsSinceEpoch(r['whenMs'] as int)}', (r) => Db.deleteBooking(r['id'] as int)),
                  _list(d[1], (r) => '${r['title']}', (r) => Db.deleteNote(r['id'] as int)),
                  _list(d[2], (r) => '${r['name']}', null),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _list(List<Map<String, Object?>> rows, String Function(Map<String, Object?>) label, Future<void> Function(Map<String, Object?>)? del) =>
      ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        for (final r in rows)
          ListTile(
            title: Text(label(r)),
            trailing: del == null ? null : IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
              await del(r);
              setState(() {});
            }),
          ),
      ]);
}
