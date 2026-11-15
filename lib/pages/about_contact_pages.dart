import 'dart:async';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_number_flow/flutter_number_flow.dart';
import 'package:iconify_flutter_plus/iconify_flutter_plus.dart';
import 'package:iconify_flutter_plus/icons/mdi.dart';

import '../l10n/app_strings.dart';
import '../pages_registry.dart';
import '../services/rss_pdf_service.dart';
import '../widgets/page_shell.dart';
import '../widgets/share_bar.dart';
import '../widgets/textured_button.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  double _hours = 1240, _apps = 37;
  late final Timer _t;
  final _r = Random();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 3), (_) => setState(() {
          _hours += 1 + _r.nextInt(8);
          if (_r.nextBool()) _apps += 1;
        }));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  Widget _stat(String label, double v, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Icon(icon, size: 32),
            NumberFlow(
              value: v,
              animationStyle: NumberFlowAnimation.slide,
              duration: const Duration(milliseconds: 600),
              textStyle: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
            ),
            Text(label),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'about',
      title: context.tr('about'),
      crumbs: [context.tr('about')],
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        const AutoSizeText('Interactive ecosystem panoramas and app development services.',
            maxLines: 3, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: 260, child: _stat('Service hours delivered', _hours, Icons.schedule)),
          SizedBox(width: 260, child: _stat('Mobile applications shipped', _apps, Icons.phone_android)),
        ]),
        const SizedBox(height: 16),
        ShareBar(text: 'Ecosystem Viewer $baseUrl/about'),
      ]),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'contact',
      title: context.tr('contact'),
      crumbs: [context.tr('contact')],
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        const ListTile(leading: Icon(Icons.mail), title: Text('hello@animation-panoramas.example')),
        const ListTile(leading: Icon(Icons.phone), title: Text('+00 000 000 000')),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          ShareBar(text: 'Ecosystem Viewer $baseUrl'),
          IconButton.filledTonal(
            tooltip: context.tr('rss'),
            icon: const Iconify(Mdi.rss, size: 22),
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _RssSheet()),
          ),
          TexturedButton(label: context.tr('admin'), icon: Icons.lock, onPressed: () => openPage(context, 'admin')),
        ]),
      ]),
    );
  }
}

class _RssSheet extends StatelessWidget {
  const _RssSheet();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(shrinkWrap: true, children: [
        for (final p in appPages)
          ListTile(
            leading: const Iconify(Mdi.rss, color: Colors.orange),
            title: Text(p.title),
            subtitle: Text('${p.url}/rss.xml'),
            trailing: const Icon(Icons.copy, size: 18),
            onTap: () async {
              final xml = await RssService.build(p);
              await Clipboard.setData(ClipboardData(text: xml));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.title}: RSS XML copied')));
              }
            },
          ),
      ]),
    );
  }
}
