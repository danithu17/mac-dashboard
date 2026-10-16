import 'dart:math';
import 'package:flutter/cupertino.dart';

class ActivityRingsWidget extends StatelessWidget {
  final double overallPct;
  final double craftPct;
  final double vitalityPct;
  final double size;

  const ActivityRingsWidget({
    super.key,
    required this.overallPct,
    required this.craftPct,
    required this.vitalityPct,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingsPainter(
              overallPct: overallPct.clamp(0.0, 1.0),
              craftPct: craftPct.clamp(0.0, 1.0),
              vitalityPct: vitalityPct.clamp(0.0, 1.0),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(overallPct * 100).round()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'GOAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFA114F),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double overallPct;
  final double craftPct;
  final double vitalityPct;

  _RingsPainter({
    required this.overallPct,
    required this.craftPct,
    required this.vitalityPct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.085;

    final rOverall = (size.width / 2) - (strokeWidth / 2);
    final rCraft = rOverall - strokeWidth - 4;
    final rVitality = rCraft - strokeWidth - 4;

    _drawRing(canvas, center, rOverall, strokeWidth, const Color(0x33FA114F), const Color(0xFFFA114F), overallPct);
    _drawRing(canvas, center, rCraft, strokeWidth, const Color(0x33A4FF00), const Color(0xFFA4FF00), craftPct);
    _drawRing(canvas, center, rVitality, strokeWidth, const Color(0x3300F5EA), const Color(0xFF00F5EA), vitalityPct);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double strokeWidth, Color trackColor, Color fillColor, double pct) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    canvas.drawCircle(center, radius, trackPaint);

    // Foreground progress arc
    if (pct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * pct,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.overallPct != overallPct ||
        oldDelegate.craftPct != craftPct ||
        oldDelegate.vitalityPct != vitalityPct;
  }
}
