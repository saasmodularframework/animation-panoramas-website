import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../widgets/sprite_sheet_animator.dart';

class EcosystemSpriteLoader extends StatefulWidget {
  final String imagePath;
  final int totalFrames;
  final int columns;
  final int rows;

  const EcosystemSpriteLoader({
    super.key,
    required this.imagePath,
    required this.totalFrames,
    required this.columns,
    required this.rows,
  });

  @override
  State<EcosystemSpriteLoader> createState() => _EcosystemSpriteLoaderState();
}

class _EcosystemSpriteLoaderState extends State<EcosystemSpriteLoader> {
  ui.Image? _loadedImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant EcosystemSpriteLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load(widget.imagePath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _loadedImage = frame.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadedImage == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: SpriteSheetAnimator(
        image: _loadedImage!,
        assetName: widget.imagePath,
        totalFrames: widget.totalFrames,
        columns: widget.columns,
        rows: widget.rows,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}


