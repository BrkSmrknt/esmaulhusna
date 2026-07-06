import 'package:flutter/material.dart';

/// Belirli ilerleme eşiklerinde (ör. her %10) ekranda beliren, büyükçe
/// parlayarak yukarı süzülen ve solan sayı animasyonu. Ripple'dan daha
/// belirgin bir "yol kat ettin" geri bildirimi verir.
class MilestoneFloat extends StatefulWidget {
  final int value;
  final VoidCallback onComplete;

  const MilestoneFloat({
    super.key,
    required this.value,
    required this.onComplete,
  });

  @override
  State<MilestoneFloat> createState() => _MilestoneFloatState();
}

class _MilestoneFloatState extends State<MilestoneFloat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rise;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _rise = Tween<double>(begin: 0, end: -140).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _scale = Tween<double>(begin: 0.6, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.15),
      ),
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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // İlk %15'te belirir, kalan sürede yavaşça solar.
          final fade = _controller.value < 0.15
              ? _opacity.value
              : (1 - (_controller.value - 0.15) / 0.85).clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, _rise.value),
            child: Transform.scale(
              scale: _scale.value,
              child: Opacity(opacity: fade, child: child),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.value}',
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFB067),
                height: 1,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            Text(
              'kaldı',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: const Color(0xFFFFB067).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
