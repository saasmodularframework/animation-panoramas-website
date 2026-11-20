import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:vimeo_video_player/vimeo_video_player.dart';

import '../l10n/app_strings.dart';
import '../widgets/page_shell.dart';
import '../widgets/scene_video_carousel.dart';

const _sprites = [
  'assets/sprites/sprite-01.png', 'assets/sprites/sprite-02.png', 'assets/sprites/sprite-03.png',
  'assets/sprites/sprite-04.png', 'assets/sprites/sprite--05.png', 'assets/sprites/sprite--06.png',
  'assets/sprites/sprite--07.png',
];
const _gifs = [
  'https://govsim.pythonanywhere.com/static/sticky-timetable.gif',
  'https://govsim.pythonanywhere.com/static/metrics-appliances.gif',
  'https://govsim.pythonanywhere.com/static/multiserver-fiction.gif',
  'https://govsim.pythonanywhere.com/static/portable-pulls.gif',
];


class PicturesPage extends StatelessWidget {
  const PicturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'pictures',
      title: context.tr('pictures'),
      crumbs: [context.tr('pictures')],
      child: LayoutBuilder(
        builder: (c, box) => FlutterCarousel(
          height: box.maxHeight - 8,
          scrollDirection: Axis.vertical, 
          effect: CarouselEffect.parallax(),
          autoPlay: CarouselAutoPlay(interval: const Duration(seconds: 6)),
          indicator: const CarouselIndicator(
            painter: CircularWaveIndicator(style: SlideIndicatorStyle(activeColor: Color(0xFF9B8CFF))),
            placement: CarouselIndicatorPlacement.below,
          ),
          items: [for (int i = 0; i < _sprites.length; i++) _ZoomImage(path: _sprites[i], gif: _gifs[i % _gifs.length])],
        ),
      ),
    );
  }
}

class _ZoomImage extends StatefulWidget {
  final String path, gif;
  const _ZoomImage({required this.path, required this.gif});
  @override
  State<_ZoomImage> createState() => _ZoomImageState();
}

class _ZoomImageState extends State<_ZoomImage> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(duration: const Duration(milliseconds: 180), vsync: this);
  Animation<double>? _anim;
  VoidCallback? _l;
  final _scales = [1.0, 3.0];
  Offset? _gifAt;
  Timer? _gifTimer;

  @override
  void dispose() {
    _gifTimer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  void _onDoubleTap(ExtendedImageGestureState state) {
    final p = state.pointerDownPosition ?? Offset.zero;
    final begin = state.gestureDetails!.totalScale!;
    final end = begin == _scales[0] ? _scales[1] : _scales[0];
    if (_l != null) _anim?.removeListener(_l!);
    _ac..stop()..reset();
    _l = () => state.handleDoubleTap(scale: _anim!.value, doubleTapPosition: p);
    _anim = _ac.drive(Tween<double>(begin: begin, end: end))..addListener(_l!);
    _ac.forward();

    setState(() => _gifAt = p);
    _gifTimer?.cancel();
    _gifTimer = Timer(const Duration(milliseconds: 1800), () => mounted ? setState(() => _gifAt = null) : null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: ExtendedImage.asset(
          widget.path,
          fit: BoxFit.contain,
          mode: ExtendedImageMode.gesture,
          initGestureConfigHandler: (s) => GestureConfig(
            minScale: 0.9, animationMinScale: 0.7, maxScale: 4.0, animationMaxScale: 4.5,
            speed: 1.0, inertialSpeed: 100.0, initialScale: 1.0, inPageView: false, initialAlignment: InitialAlignment.center,
          ),
          onDoubleTap: _onDoubleTap,
        ),
      ),
      if (_gifAt != null)
        Positioned(
          left: _gifAt!.dx - 60, top: _gifAt!.dy - 60, width: 120,
          child: IgnorePointer(child: Image.network(widget.gif, errorBuilder: (_, __, ___) => const SizedBox())),
        ),
    ]);
  }
}

const _sceneVideos = [
  'assets/videos/scene-01.mp4', 'assets/videos/scene-02.mp4', 'assets/videos/scene-03.mp4',
  'assets/videos/scene-04.mp4', 'assets/videos/scene-05.mp4', 'assets/videos/scene-06.mp4',
  'assets/videos/scene-07.mp4',
];

class VideosPage extends StatelessWidget {
  const VideosPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'videos',
      title: context.tr('videos'),
      crumbs: [context.tr('videos')],
      child: const SceneVideoCarousel(assets: _sceneVideos, fallback: _VideoCarouselView()),
    );
  }
}

class _VideoCarouselView extends StatelessWidget {
  const _VideoCarouselView();
  @override
  Widget build(BuildContext context) => _MediaCarousel(
        count: _sceneVideos.length,
        labelOf: (i) => 'Scene 0${i + 1}',
        builder: (context, i, active) => _VideoTile(n: i + 1, active: active),
      );
}

/// Generic carousel: PageView + auto advance (paused on hover) + manual arrows, dots and swipe.
class _MediaCarousel extends StatefulWidget {
  const _MediaCarousel({
    required this.count,
    required this.builder,
    required this.labelOf,
    this.interval = const Duration(seconds: 8),
  });
  final int count;
  final Widget Function(BuildContext context, int index, bool active) builder;
  final String Function(int index) labelOf;
  final Duration interval;

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  final _pc = PageController();
  Timer? _timer;
  int _i = 0;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!_hover && mounted) _go(_i + 1);
    });
  }

  void _go(int target) {
    final n = widget.count;
    final t = ((target % n) + n) % n;
    if (!_pc.hasClients) return;
    if (t == 0 && _i == n - 1) {
      _pc.jumpToPage(0); 
    } else {
      _pc.animateToPage(t, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.count;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      child: MouseRegion(
        onEnter: (_) => _hover = true,
        onExit: (_) => _hover = false,
        child: Column(children: [
          Expanded(
            child: Stack(children: [
              ScrollConfiguration(
     
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
                ),
                child: PageView.builder(
                  controller: _pc,
                  itemCount: n,
                  onPageChanged: (i) {
                    setState(() => _i = i);
                    _restart(); 
                  },
                  itemBuilder: (context, i) => Center(
                    child: LayoutBuilder(builder: (context, b) {
                      final w = math.min(b.maxWidth - 120, math.max(240.0, (b.maxHeight - 56) * 16 / 9));
                      return SizedBox(width: math.max(200.0, w), child: widget.builder(context, i, i == _i));
                    }),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton.filledTonal(
                  tooltip: 'Previous',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _go(_i - 1),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: 'Next',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _go(_i + 1),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var d = 0; d < n; d++)
              GestureDetector(
                onTap: () => _go(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: d == _i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: d == _i ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text('${_i + 1} / $n  ·  ${widget.labelOf(_i)}', style: const TextStyle(fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

class _VideoTile extends StatefulWidget {
  final int n;
  final bool active; // only the visible slide plays
  const _VideoTile({required this.n, this.active = true});
  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  late final VideoPlayerController _c;
  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.asset('assets/videos/scene-0${widget.n}.mp4')
      ..setLooping(true)
      ..setVolume(0) 
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        if (widget.active) _c.play();
      });
  }

  @override
  void didUpdateWidget(covariant _VideoTile old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active && _c.value.isInitialized) {
      widget.active ? _c.play() : _c.pause();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _fullscreen() {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(children: [
            Center(child: AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c))),
            const Positioned(top: 8, left: 8, child: BackButton(color: Colors.white)),
          ]),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _c.value.isInitialized;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(8), child: Text('Scene 0${widget.n}', style: const TextStyle(fontWeight: FontWeight.bold))),
        AspectRatio(
          aspectRatio: ready ? _c.value.aspectRatio : 16 / 9,
          child: Stack(children: [
            Positioned.fill(child: ready ? VideoPlayer(_c) : const ColoredBox(color: Colors.black12)),
            Positioned(right: 4, bottom: 4, child: IconButton.filledTonal(icon: const Icon(Icons.fullscreen), onPressed: ready ? _fullscreen : null)),
          ]),
        ),
      ]),
    );
  }
}

const _vimeoIds = [
  '1246650631', '1246650631', '1246650631', '1246650631', '1246650631', '1246650631', '1246650631',
];

class VimeoPage extends StatelessWidget {
  const VimeoPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageShell(
      slug: 'videos-vimeo',
      title: context.tr('vimeo'),
      crumbs: [context.tr('vimeo')],
      child: _MediaCarousel(
        count: _vimeoIds.length,
        labelOf: (i) => 'Vimeo ${i + 1}',

        builder: (context, i, active) => AspectRatio(
          aspectRatio: 16 / 9,
          child: active
              ? VimeoVideoPlayer(
                  key: ValueKey('vimeo-$i'),
                  videoId: _vimeoIds[i],
                  isAutoPlay: true,
                  isMuted: true,
                  isLooping: true,
                  showControls: true,
                  enableFullScreenOnPlay: false,
                  onReady: () => debugPrint('vimeo #${i + 1} ready'),
                )
              : const ColoredBox(color: Colors.black12),
        ),
      ),
    );
  }
}
