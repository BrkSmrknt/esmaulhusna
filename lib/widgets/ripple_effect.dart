import 'package:flutter/material.dart';

/// Dokunulan noktadan dışa doğru genişleyip solan ışık halkaları (su damlası
/// etkisi). Animasyon bitince [onComplete] çağrılır.
class RippleEffect extends StatefulWidget {
  final VoidCallback onComplete;
  final double maxRadius;

  const RippleEffect({
    super.key,
    required this.onComplete,
    this.maxRadius = 95,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radius;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _radius = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
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
            painter: _RipplePainter(
              progress: _radius.value,
              opacity: _opacity.value,
              maxRadius: widget.maxRadius,
            ),
          );
        },
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final double opacity;
  final double maxRadius;

  _RipplePainter({
    required this.progress,
    required this.opacity,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = progress * maxRadius;

    // Yumuşak iç parıltı
    if (outerRadius > 1) {
      final glow = Paint()
        ..color = const Color(0xFFFF8E53).withValues(alpha: opacity * 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, outerRadius * 0.75, glow);
    }

    // Ana halka
    final ring = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, outerRadius, ring);

    // Arkadan gelen ikinci, daha soluk halka (damla dalgası hissi)
    final innerRadius = outerRadius * 0.6;
    if (innerRadius > 1) {
      final ring2 = Paint()
        ..color = const Color(0xFFFF8E53).withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, innerRadius, ring2);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
