import 'package:flutter/material.dart';
import 'package:giffy_dialog/giffy_dialog.dart';

import '../models/ecosystem.dart';
import '../pages_registry.dart';

const String kGiffyGifAsset = 'assets/gifs/example.gif';

const double kGiffyDim = 0.4;

Future<void> openSceneWithGiffy(BuildContext context, Ecosystem e) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => GiffyDialog.image(
     
      Image.asset(
        kGiffyGifAsset,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        color: Colors.black.withValues(alpha: kGiffyDim),
        colorBlendMode: BlendMode.srcOver,
        errorBuilder: (_, __, ___) => const SizedBox(height: 200),
      ),
      title: Text(e.title, textAlign: TextAlign.center),
      content: const Text(
        'This is gif animation by means of rive giffy dialog.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Revoke'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('More'),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) openScene(context, e);
}
