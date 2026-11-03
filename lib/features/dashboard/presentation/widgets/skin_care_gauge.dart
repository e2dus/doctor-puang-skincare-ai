import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'skin_care_status.dart';

/// 게이지 커스텀 페인터
class SkinCareGaugePainter extends CustomPainter {
  final int score;
  final double angle;
  final SkinCareStatus status;
  final Color primaryColor;
  final Color secondaryColor;

  SkinCareGaugePainter({
    required this.score,
    required this.angle,
    required this.status,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 0.4;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final scoreAngle = angle * math.pi / 180;
    final totalAngle = math.pi;

    // 배경 원호
    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, totalAngle, false, backgroundPaint);

    // GOOD까지의 각도 (0-80점 = 0-144도)
    final goodEndAngle = 144 * math.pi / 180;

    // 그라데이션
    final gradient = SweepGradient(
      startAngle: math.pi,
      endAngle: math.pi + goodEndAngle,
      colors: [primaryColor, secondaryColor],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    if (scoreAngle <= goodEndAngle) {
      canvas.drawArc(rect, math.pi, scoreAngle, false, gradientPaint);
    } else {
      canvas.drawArc(rect, math.pi, goodEndAngle, false, gradientPaint);

      final excellentPaint = Paint()
        ..color = secondaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      final excellentStartAngle = math.pi + goodEndAngle;
      final excellentAngle = scoreAngle - goodEndAngle;
      canvas.drawArc(
        rect,
        excellentStartAngle,
        excellentAngle,
        false,
        excellentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SkinCareGaugePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.score != score ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
