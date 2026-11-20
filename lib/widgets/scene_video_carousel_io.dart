import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:video_carousel/video_carousel.dart';

import 'smart_snack.dart';

class SceneVideoCarousel extends StatefulWidget {
  const SceneVideoCarousel({super.key, required this.assets, required this.fallback});

  final List<String> assets;
  final Widget fallback;

  @override
  State<SceneVideoCarousel> createState() => _SceneVideoCarouselState();
}

class _SceneVideoCarouselState extends State<SceneVideoCarousel> {
  static final bool _supported = Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  List<File>? _files;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (_supported) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
    }
  }

  Future<void> _prepare() async {
    final progress = SmartSnack.loading('Preparing videos');
    try {
      final dir = await getTemporaryDirectory();
      final files = <File>[];
      for (final asset in widget.assets) {
        final data = await rootBundle.load(asset);
        final file = File('${dir.path}/${asset.split('/').last}');
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
        files.add(file);
      }
      if (mounted) setState(() => _files = files);
    } catch (e) {
      debugPrint('SceneVideoCarousel: $e');
      SmartSnack.warning('Videos unavailable, showing the list instead');
      if (mounted) setState(() => _failed = true);
    } finally {
      progress.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    if (!_supported || _failed) return widget.fallback;
    if (files == null) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, box) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        child: Align(
          alignment: Alignment.topCenter,
          child: VideoCarousel(
            files: files,
            height: (box.maxHeight - 108).clamp(240.0, 560.0).toDouble(),
            autoPlay: true,
          ),
        ),
      ),
    );
  }
}
