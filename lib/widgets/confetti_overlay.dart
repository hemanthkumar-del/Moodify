import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool show;
  final Widget child;

  const ConfettiOverlay({
    Key? key,
    required this.show,
    required this.child,
  }) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _generateParticles();
      _controller.forward(from: 0.0);
    }
  }

  void _generateParticles() {
    _particles.clear();
    final colors = [
      Colors.redAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.yellowAccent,
      Colors.orangeAccent,
    ];

    for (int i = 0; i < 80; i++) {
      final double angle = _random.nextDouble() * 2 * pi;
      final double speed = _random.nextDouble() * 300 + 150;
      _particles.add(
        _ConfettiParticle(
          color: colors[_random.nextInt(colors.length)],
          angle: angle,
          speed: speed,
          size: _random.nextDouble() * 8 + 6,
          rotationSpeed: _random.nextDouble() * 4 * pi,
          shape: _random.nextInt(3), // 0: circle, 1: rect, 2: triangle
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show || _controller.isAnimating)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final int shape;

  _ConfettiParticle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 100);

    for (final particle in particles) {
      // Physics calculation for particle path:
      // Distance grows with progress, gravity pulls down
      final double time = progress * 1.5;
      final double distance = particle.speed * time;
      
      final double dx = cos(particle.angle) * distance;
      final double dy = sin(particle.angle) * distance + (500 * time * time); // gravity

      final x = center.dx + dx;
      final y = center.dy + dy;

      // Keep particles inside the screen bounds
      if (x < 0 || x > size.width || y > size.height) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotationSpeed * progress);

      final double r = particle.size / 2;
      if (particle.shape == 0) {
        // Circle
        canvas.drawCircle(Offset.zero, r, paint);
      } else if (particle.shape == 1) {
        // Rectangle
        canvas.drawRect(Rect.fromLTRB(-r, -r / 2, r, r / 2), paint);
      } else {
        // Triangle
        final path = Path()
          ..moveTo(0, -r)
          ..lineTo(r, r)
          ..lineTo(-r, r)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
