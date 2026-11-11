import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Configuration data class for sprite sheets
class SpriteConfig {
  final int columns;
  final int rows;
  final int totalFrames;

  const SpriteConfig({
    required this.columns,
    required this.rows,
    required this.totalFrames,
  });
}

class SpriteSheetAnimator extends StatefulWidget {
  final ui.Image image;
  final String assetName; // Used to look up the exact grid ratio automatically
  final Duration duration;
  final BoxFit fit;

  // Optional manual overrides if needed
  final int? columns;
  final int? rows;
  final int? totalFrames;

  const SpriteSheetAnimator({
    Key? key,
    required this.image,
    required this.assetName,
    this.duration = const Duration(seconds: 1),
    this.fit = BoxFit.contain,
    this.columns,
    this.rows,
    this.totalFrames,
  }) : super(key: key);

  /// Centralized mapping of exact grid ratios for each specific sprite sheet filename
  static const Map<String, SpriteConfig> spriteRegistry = {
    'sprite-01.png': SpriteConfig(columns: 5, rows: 3, totalFrames: 15),
    'sprite-02.png': SpriteConfig(columns: 4, rows: 6, totalFrames: 24),
    'sprite-03.png': SpriteConfig(columns: 5, rows: 4, totalFrames: 20),
    'sprite-04.png': SpriteConfig(columns: 5, rows: 3, totalFrames: 15),
    'sprite--05.png': SpriteConfig(columns: 4, rows: 3, totalFrames: 12),
    'sprite--06.png': SpriteConfig(columns: 5, rows: 3, totalFrames: 15),
    'sprite--07.png': SpriteConfig(columns: 4, rows: 3, totalFrames: 12),
  };

  @override
  State<SpriteSheetAnimator> createState() => _SpriteSheetAnimatorState();
}

class _SpriteSheetAnimatorState extends State<SpriteSheetAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SpriteSheetAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SpriteConfig _resolveConfig() {
    // Extract filename from path if a full asset path like 'assets/sprites/sprite-01.png' is passed
    String cleanKey = widget.assetName.split('/').last;

    // Fallback to registry configuration or defaults if not found
    SpriteConfig config = SpriteSheetAnimator.spriteRegistry[cleanKey] ??
        const SpriteConfig(columns: 4, rows: 4, totalFrames: 16);

    return SpriteConfig(
      columns: widget.columns ?? config.columns,
      rows: widget.rows ?? config.rows,
      totalFrames: widget.totalFrames ?? config.totalFrames,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        int frameIndex = (_controller.value * config.totalFrames)
            .floor()
            .clamp(0, config.totalFrames - 1);
            
        return CustomPaint(
          painter: SpritePainter(
            image: widget.image,
            frameIndex: frameIndex,
            columns: config.columns,
            rows: config.rows,
            totalFrames: config.totalFrames,
            fit: widget.fit,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frameIndex;
  final int columns;
  final int rows;
  final int totalFrames;
  final BoxFit fit;

  SpritePainter({
    required this.image,
    required this.frameIndex,
    required this.columns,
    required this.rows,
    required this.totalFrames,
    required this.fit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    double frameWidth = image.width / columns;
    double frameHeight = image.height / rows;

    int col = frameIndex % columns;
    int row = frameIndex ~/ columns;

    Rect srcRect = Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

    Rect dstRect = _calculateDestinationRect(size, frameWidth, frameHeight);

    Paint paint = Paint()..filterQuality = FilterQuality.low;

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  Rect _calculateDestinationRect(Size widgetSize, double srcWidth, double srcHeight) {
    if (fit == BoxFit.fill) {
      return Rect.fromLTWH(0, 0, widgetSize.width, widgetSize.height);
    }

    double srcAspect = srcWidth / srcHeight;
    double widgetAspect = widgetSize.width / widgetSize.height;

    double dstWidth = widgetSize.width;
    double dstHeight = widgetSize.height;

    if (fit == BoxFit.contain) {
      if (srcAspect > widgetAspect) {
        dstHeight = widgetSize.width / srcAspect;
      } else {
        dstWidth = widgetSize.height * srcAspect;
      }
    } else if (fit == BoxFit.cover) {
      if (srcAspect > widgetAspect) {
        dstWidth = widgetSize.height * srcAspect;
      } else {
        dstHeight = widgetSize.width / srcAspect;
      }
    }

    double left = (widgetSize.width - dstWidth) / 2;
    double top = (widgetSize.height - dstHeight) / 2;

    return Rect.fromLTWH(left, top, dstWidth, dstHeight);
  }

  @override
  bool shouldRepaint(covariant SpritePainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex ||
        oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.totalFrames != totalFrames ||
        oldDelegate.fit != fit;
  }
}