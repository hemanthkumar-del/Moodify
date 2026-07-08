import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GradientCover extends StatelessWidget {
  final String title;
  final String artist;
  final String mood;
  final double size;
  final double borderRadius;
  final bool animate;

  const GradientCover({
    Key? key,
    required this.title,
    required this.artist,
    required this.mood,
    this.size = 120,
    this.borderRadius = 20,
    this.animate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate a pseudo-random hash value from title + artist
    final int hash = (title + artist).hashCode;
    final Random random = Random(hash);

    final moodColors = AppColors.getMoodGradient(mood);
    final primaryColor = moodColors[0];
    final secondaryColor = moodColors[1];
    
    // Choose 3rd color for richer gradient
    final accentColors = [
      Colors.deepPurpleAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.amberAccent,
      Colors.tealAccent,
      Colors.orangeAccent,
    ];
    final tertiaryColor = accentColors[random.nextInt(accentColors.length)];

    final angle1 = random.nextDouble() * 2 * pi;
    final angle2 = angle1 + pi / 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Base Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Nested design element 1: Glass circle
            Positioned(
              top: random.nextDouble() * (size / 2) - (size / 4),
              left: random.nextDouble() * (size / 2) - (size / 4),
              child: Transform.rotate(
                angle: angle1,
                child: Container(
                  width: size * 0.7,
                  height: size * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tertiaryColor.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Nested design element 2: Intersecting shape
            Positioned(
              bottom: random.nextDouble() * (size / 2) - (size / 4),
              right: random.nextDouble() * (size / 2) - (size / 4),
              child: Transform.rotate(
                angle: angle2,
                child: Container(
                  width: size * 0.8,
                  height: size * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.3),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        primaryColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Premium Mesh Grid Overlay
            Opacity(
              opacity: 0.08,
              child: CustomPaint(
                size: Size(size, size),
                painter: _GridPainter(random.nextInt(4) + 3),
              ),
            ),

            // Center emoji or music icon watermark
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: size * 0.22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int lines;
  _GridPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double stepX = size.width / lines;
    final double stepY = size.height / lines;

    for (int i = 1; i < lines; i++) {
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * stepY),
        Offset(size.width, i * stepY),
        paint,
      );
      // Vertical lines
      canvas.drawLine(
        Offset(i * stepX, 0),
        Offset(i * stepX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
