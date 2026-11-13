import 'package:flutter/material.dart';

class TexturedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool compact;
  const TexturedButton({super.key, required this.label, required this.onPressed, this.icon, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.tertiary, cs.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: TexturePatternPainter(color: Colors.white.withOpacity(0.14)))),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18, vertical: compact ? 6 : 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: compact ? 12 : 14)),
                if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: 16, color: cs.onPrimary)],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class TexturePatternPainter extends CustomPainter {
  final Color color;
  TexturePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5;
    for (double i = -size.height; i < size.width + size.height; i += 8) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
