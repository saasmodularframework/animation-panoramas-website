import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../data/ecosystems.dart';
import '../l10n/app_strings.dart';
import '../models/ecosystem.dart';
import '../pages_registry.dart';
import '../widgets/page_shell.dart';
import '../widgets/share_bar.dart';
import '../widgets/textured_button.dart';

class ScenesPage extends StatelessWidget {
  const ScenesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final list = getEcosystems();
    return PageShell(
      slug: 'scenes',
      title: context.tr('scenes'),
      crumbs: [context.tr('scenes')],
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.95),
        itemCount: list.length,
        itemBuilder: (c, i) => _SceneCard(e: list[i]),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  final Ecosystem e;
  const _SceneCard({required this.e});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [e.background.top, e.background.bottom])),
        child: Column(children: [
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.topLeft, 
                widthFactor: 1 / e.spriteColumns,
                heightFactor: 1 / e.spriteRows,
                child: Image.asset(e.spritePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: AutoSizeText(e.title, maxLines: 1, minFontSize: 11, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(width: 8),
              TexturedButton(label: context.tr('more'), compact: true, onPressed: () => openScene(context, e)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class SceneDetailPage extends StatelessWidget {
  final Ecosystem ecosystem;
  const SceneDetailPage({super.key, required this.ecosystem});

  @override
  Widget build(BuildContext context) {
    final e = ecosystem;
    return PageShell(
      slug: 'scene/${e.slug}',
      title: e.title,
      ecosystem: e,
      crumbs: [context.tr('scenes'), e.title],
      child: Column(children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [e.background.top, e.background.bottom])),
            child: ModelViewer(src: e.modelPath, alt: e.title, autoRotate: true, cameraControls: true, backgroundColor: Colors.transparent),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 100, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.description),
            if (e.fact != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(e.fact!, style: const TextStyle(fontStyle: FontStyle.italic))),
            const SizedBox(height: 8),
            ShareBar(text: '${e.title} – ${e.description} $baseUrl/scene/${e.slug}'),
          ]),
        ),
      ]),
    );
  }
}
