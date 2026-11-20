import 'package:flutter/material.dart';

class GlobalGifBackground extends StatelessWidget {
  const GlobalGifBackground({
    super.key,
    required this.isDay,
    required this.child,
    this.scrimColor,
  });

  final bool isDay;
  final Widget child;
  final Color? scrimColor;

  static const _dayGif = 'assets/gifs/bg.gif';
  static const _nightGif = 'assets/gifs/bg_ev.gif';

  @override
  Widget build(BuildContext context) {
    final assetPath = isDay ? _dayGif : _nightGif;
    final overlayColor = scrimColor ??
        (isDay
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.35));

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            assetPath,
            key: ValueKey(assetPath),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: overlayColor),
        ),
        child,
      ],
    );
  }
}