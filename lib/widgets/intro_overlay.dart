import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ecosystem_sprite_loader.dart';

class IntroOverlay extends StatefulWidget {
  const IntroOverlay({super.key});

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> {
  static const _prefKey = 'intro_seen_v1';
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_prefKey) ?? false;
      if (!seen && mounted) setState(() => _show = true);
    } catch (e) {
      debugPrint('Intro check failed: $e');
    }
  }

  Future<void> _finish() async {
    if (mounted) setState(() => _show = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (e) {
      debugPrint('Intro save failed: $e');
    }
  }

  Widget _sprite(String file, int frames, int cols, int rows) => SizedBox(
        height: 260,
        child: EcosystemSpriteLoader(
          imagePath: 'assets/sprites/$file',
          totalFrames: frames,
          columns: cols,
          rows: rows,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();

    const decoration = PageDecoration(
      pageColor: Colors.transparent,
      titleTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
      bodyTextStyle: TextStyle(fontSize: 16, color: Colors.white70),
    );

    final pages = <PageViewModel>[
      PageViewModel(
        title: 'Explore living panoramas',
        body: 'Every scene is an animated ecosystem you can open, rotate and explore.',
        image: _sprite('sprite--05.png', 12, 4, 3),
        decoration: decoration,
      ),
      PageViewModel(
        title: 'Live climate data',
        body: 'Precipitation, temperature, vegetation and drought pages combine live '
            'values with reference tables and charts.',
        image: _sprite('sprite--06.png', 15, 5, 3),
        decoration: decoration,
      ),
      PageViewModel(
        titleWidget: const SizedBox.shrink(),
        bodyWidget: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _finish, child: const Text('Skip')),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Start',
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: _finish,
            ),
          ],
        ),
        image: _sprite('sprite--07.png', 12, 4, 3),
        decoration: decoration,
      ),
    ];

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: IntroductionScreen(
          globalBackgroundColor: const Color(0xF2101418),
          pages: pages,
          showSkipButton: true,
          skip: const Text('Skip', style: TextStyle(color: Colors.white)),
          next: const Icon(Icons.arrow_forward, color: Colors.white),
          done: const Icon(Icons.arrow_forward, color: Colors.white),
          onSkip: _finish,
          onDone: _finish,
          dotsDecorator: const DotsDecorator(activeColor: Colors.white, color: Colors.white38),
        ),
      ),
    );
  }
}
