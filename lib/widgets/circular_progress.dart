import 'dart:math';
import 'package:flutter/material.dart';

class CircularProgressWidget extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Widget child;

  const CircularProgressWidget({
    super.key,
    required this.progress,
    this.size = 320,
    this.strokeWidth = 22,
    this.trackColor = const Color(0xFF2A2A2A),
    this.child = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          trackColor: trackColor,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle - subtle track ring
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Outer glow
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x30FF6B35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 30))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 20
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, glowPaint);

    // Progress arc - gradient effect
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: const [
          Color(0xFFFF6B35),
          Color(0xFFFF8E53),
          Color(0xFFFF6B35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Endpoint glow dot
    if (progress > 0.01) {
      final dotAngle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(dotAngle);
      final dotY = center.dy + radius * sin(dotAngle);

      final dotPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(dotX, dotY), radius: 15))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 15, dotPaint);
      canvas.drawCircle(Offset(dotX, dotY), 5,
          Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor;
  }
}
