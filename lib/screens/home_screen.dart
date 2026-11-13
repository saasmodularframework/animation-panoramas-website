import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../data/ecosystems.dart';
import '../l10n/app_strings.dart';
import '../pages_registry.dart';
import '../widgets/page_shell.dart';
import '../widgets/textured_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _icons = <String, IconData>{
    'main': Icons.public,
    'metrics': Icons.query_stats,
    'scenes': Icons.grid_view,
    'pictures': Icons.photo_library,
    'videos': Icons.videocam,
    'videos-vimeo': Icons.smart_display,
    'about': Icons.info_outline,
    'contact': Icons.contact_mail,
    'app-dev-services': Icons.phone_android,
    'coding-agenda': Icons.event,
    'notes': Icons.note_alt,
    'chart': Icons.bar_chart,
    'pdf-library': Icons.picture_as_pdf,
    'admin': Icons.lock,
  };

  @override
  Widget build(BuildContext context) {
    final pages = appPages.where((p) => p.slug != 'home').toList();
    final scenes = getEcosystems();
    final t = Theme.of(context).textTheme;
    return PageShell(
      slug: 'home',
      title: context.tr('home'),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        AutoSizeText(context.tr('appTitle'), maxLines: 1, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${pages.length} pages · ${scenes.length} scenes'),
        const SizedBox(height: 16),
        Text(context.tr('scenes'), style: t.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in scenes) ActionChip(label: Text(e.title), onPressed: () => openScene(context, e)),
        ]),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 170),
          itemCount: pages.length,
          itemBuilder: (_, i) {
            final p = pages[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(_icons[p.slug] ?? Icons.article),
                    const SizedBox(width: 8),
                    Expanded(child: AutoSizeText(p.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 6),
                  Expanded(child: Text(p.description, maxLines: 3, overflow: TextOverflow.ellipsis)),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TexturedButton(label: context.tr('more'), compact: true, onPressed: () => openPage(context, p.slug)),
                  ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }
}
