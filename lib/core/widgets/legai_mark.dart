import 'package:flutter/material.dart';

import '../theme/legai_colors.dart';
import '../theme/legai_theme.dart';

/// The LegAI scales mark, drawn in code so it stays crisp at any size and
/// follows the theme. The gold ring on the post comes from the logo.
class LegaiMark extends StatelessWidget {
  const LegaiMark({
    super.key,
    this.size = 28,
    this.color,
    this.ringColor,
    this.strokeWidth = 1.8,
  });

  final double size;
  final Color? color;
  final Color? ringColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: LegaiMarkPainter(
          color: color ?? c.text,
          ringColor: ringColor ?? c.gold,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Mark plus the serif "LegAI" wordmark.
class LegaiWordmark extends StatelessWidget {
  const LegaiWordmark({super.key, this.markSize = 28, this.fontSize = 25});

  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LegAI',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LegaiMark(size: markSize),
            SizedBox(width: markSize * 0.3),
            Text(
              'LegAI',
              style: TextStyle(
                fontFamily: LegaiFonts.serif,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.25,
                color: context.colors.text,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegaiMarkPainter extends CustomPainter {
  LegaiMarkPainter({
    required this.color,
    required this.ringColor,
    this.strokeWidth = 1.8,
  });

  final Color color;
  final Color ringColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // The artwork is drawn on a 32 × 32 grid.
    final s = size.shortestSide / 32;
    canvas.save();
    canvas.translate((size.width - 32 * s) / 2, (size.height - 32 * s) / 2);
    canvas.scale(s);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(16, 5), 1.8, stroke);
    canvas.drawLine(const Offset(16, 7), const Offset(16, 24), stroke);

    final beam = Path()
      ..moveTo(4.5, 10.5)
      ..cubicTo(9, 8, 12.5, 8.2, 16, 9)
      ..cubicTo(19.5, 8.2, 23, 8, 27.5, 10.5);
    canvas.drawPath(beam, stroke);

    for (final x in const [5.5, 26.5]) {
      canvas.drawLine(Offset(x, 10.5), Offset(x - 3, 18), stroke);
      canvas.drawLine(Offset(x, 10.5), Offset(x + 3, 18), stroke);
      final pan = Path()
        ..moveTo(x - 3.5, 18)
        ..lineTo(x + 3.5, 18)
        ..arcToPoint(Offset(x - 3.5, 18), radius: const Radius.circular(3.5))
        ..close();
      canvas.drawPath(pan, fill);
      canvas.drawPath(pan, stroke);
    }

    final base = Path()
      ..moveTo(12.5, 28)
      ..cubicTo(12.5, 25.5, 14, 24.5, 16, 24.5)
      ..cubicTo(18, 24.5, 19.5, 25.5, 19.5, 28);
    canvas.drawPath(base, stroke);
    canvas.drawLine(const Offset(11, 28), const Offset(21, 28), stroke);

    canvas.drawLine(
      const Offset(14, 22.6),
      const Offset(18, 22.6),
      Paint()
        ..color = ringColor
        ..strokeWidth = strokeWidth * 1.22
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LegaiMarkPainter old) =>
      old.color != color ||
      old.ringColor != ringColor ||
      old.strokeWidth != strokeWidth;
}
