import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/flip10_colors.dart';

/// One-shot confetti burst painted over the board when the player shuts
/// the box. Removes itself via [onDone] after the animation finishes, so
/// the overlay never lingers into the next round (or golden tests).
class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1500);
  static const _colors = [
    Flip10Colors.brassTop,
    Flip10Colors.brass,
    Flip10Colors.ivory,
    Flip10Colors.accent,
    Flip10Colors.brassDeep,
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..forward();
  late final List<_Particle> _particles = _spawn(math.Random(41));

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDone();
      }
    });
  }

  static List<_Particle> _spawn(math.Random rng) {
    return List.generate(46, (i) {
      final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 0.9;
      final speed = 180 + rng.nextDouble() * 340;
      return _Particle(
        // Origin is the top-centre of the rack: fractions of size.
        origin: Offset(0.5 + (rng.nextDouble() - 0.5) * 0.4, 0.72),
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        size: 3.5 + rng.nextDouble() * 4,
        color: _colors[i % _colors.length],
        spin: (rng.nextDouble() - 0.5) * math.pi * 6,
        isCircle: rng.nextBool(),
      );
    });
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
        builder: (context, _) => CustomPaint(
          painter: _BurstPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

final class _Particle {
  const _Particle({
    required this.origin,
    required this.velocity,
    required this.size,
    required this.color,
    required this.spin,
    required this.isCircle,
  });

  /// Launch point as a fraction of the painted area.
  final Offset origin;
  final Offset velocity;
  final double size;
  final Color color;
  final double spin;
  final bool isCircle;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.particles, required this.progress});

  static const _lifeSeconds = 1.5;
  static const _gravity = 620.0;

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * _lifeSeconds;
    for (final p in particles) {
      final fade = 1.0 - Curves.easeIn.transform(progress);
      if (fade <= 0) continue;
      final x = (p.origin.dx * size.width) + p.velocity.dx * t;
      final y =
          (p.origin.dy * size.height) +
          p.velocity.dy * t +
          0.5 * _gravity * t * t;
      final s = p.size * (1 - progress * 0.4);
      final paint = Paint()
        ..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, s / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
