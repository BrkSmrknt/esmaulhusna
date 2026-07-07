import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dokunulan noktada beliren zarif bir ışık patlaması: sıcak bir çekirdek
/// parıltısı hızla büyüyüp solar, çevresine ince ışık ışınları saçar.
/// Su damlası halkalarının aksine "nurani" bir parlama hissi verir.
/// Animasyon bitince [onComplete] çağrılır.
class TapGlowEffect extends StatefulWidget {
  final VoidCallback onComplete;
  final double maxRadius;

  const TapGlowEffect({
    super.key,
    required this.onComplete,
    this.maxRadius = 90,
  });

  @override
  State<TapGlowEffect> createState() => _TapGlowEffectState();
}

class _TapGlowEffectState extends State<TapGlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.maxRadius * 2;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(size, size),
            painter: _GlowPainter(
              t: _controller.value,
              maxRadius: widget.maxRadius,
            ),
          );
        },
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double t;
  final double maxRadius;

  _GlowPainter({required this.t, required this.maxRadius});

  static const Color _core = Color(0xFFFFD9A8);
  static const Color _accent = Color(0xFFFF8E53);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Yumuşak açılış, hızlı solma.
    final eased = Curves.easeOutCubic.transform(t);
    final fade = (1.0 - t).clamp(0.0, 1.0);

    // 1) Sıcak çekirdek parıltısı (dolu radyal gradyan)
    final coreRadius = maxRadius * (0.35 + 0.55 * eased);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _core.withValues(alpha: 0.55 * fade),
          _accent.withValues(alpha: 0.28 * fade),
          _accent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, corePaint);

    // 2) Genişleyen ince ışık halkası
    final ringRadius = maxRadius * (0.2 + 0.8 * eased);
    final ringPaint = Paint()
      ..color = _core.withValues(alpha: 0.5 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1.0 - t) + 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, ringRadius, ringPaint);

    // 3) Dışa saçılan ışık ışınları (yıldız/nur hissi)
    const rayCount = 8;
    final rayInner = maxRadius * (0.35 + 0.35 * eased);
    final rayOuter = maxRadius * (0.55 + 0.45 * eased);
    final rayPaint = Paint()
      ..color = _core.withValues(alpha: 0.6 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < rayCount; i++) {
      final angle = (math.pi * 2 / rayCount) * i - math.pi / 2;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      canvas.drawLine(
        center + Offset(dx * rayInner, dy * rayInner),
        center + Offset(dx * rayOuter, dy * rayOuter),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
