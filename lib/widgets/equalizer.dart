import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class EqualizerVisualizer extends StatefulWidget {
  final List<Color> colors;
  final bool isPlaying;
  final int barCount;

  const EqualizerVisualizer({
    Key? key,
    this.colors = const [AppColors.primary, AppColors.secondary],
    this.isPlaying = true,
    this.barCount = 18,
  }) : super(key: key);

  @override
  State<EqualizerVisualizer> createState() => _EqualizerVisualizerState();
}

class _EqualizerVisualizerState extends State<EqualizerVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _peakHeights = [];
  final List<double> _currentHeights = [];
  final List<double> _speeds = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    for (int i = 0; i < widget.barCount; i++) {
      _peakHeights.add(0.0);
      _currentHeights.add(0.0);
      _speeds.add(_random.nextDouble() * 0.15 + 0.05);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.isPlaying) {
          // Compute new random heights and update peaks
          for (int i = 0; i < widget.barCount; i++) {
            // Target height
            double target = _random.nextDouble();
            
            // Apply smoothing
            _currentHeights[i] = _currentHeights[i] + (target - _currentHeights[i]) * 0.3;
            
            // Peak detection & slow decay
            if (_currentHeights[i] > _peakHeights[i]) {
              _peakHeights[i] = _currentHeights[i];
            } else {
              _peakHeights[i] = max(0.0, _peakHeights[i] - _speeds[i] * 0.1);
            }
          }
        } else {
          // Decay towards zero when paused
          for (int i = 0; i < widget.barCount; i++) {
            _currentHeights[i] = max(0.05, _currentHeights[i] - 0.05);
            _peakHeights[i] = max(0.05, _peakHeights[i] - 0.05);
          }
        }

        return CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _EqualizerPainter(
            currentHeights: _currentHeights,
            peakHeights: _peakHeights,
            colors: widget.colors,
          ),
        );
      },
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final List<double> currentHeights;
  final List<double> peakHeights;
  final List<Color> colors;

  _EqualizerPainter({
    required this.currentHeights,
    required this.peakHeights,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int barCount = currentHeights.length;
    final double spacing = 4.0;
    final double totalSpacing = spacing * (barCount - 1);
    final double barWidth = (size.width - totalSpacing) / barCount;

    final Paint barPaint = Paint()..style = PaintingStyle.fill;
    final Paint peakPaint = Paint()..style = PaintingStyle.fill;

    // Linear Gradient for bars
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      colors: colors,
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
    barPaint.shader = gradient.createShader(rect);
    
    // Peak paint color: brighter end of the gradient
    peakPaint.color = colors.last;

    for (int i = 0; i < barCount; i++) {
      final double x = i * (barWidth + spacing);
      final double barHeight = currentHeights[i] * size.height;
      final double y = size.height - barHeight;

      // Draw frequency bar
      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4.0),
      );
      canvas.drawRRect(rrect, barPaint);

      // Draw peak dot
      final double peakY = size.height - (peakHeights[i] * size.height) - 4.0;
      final double peakClampedY = peakY.clamp(0.0, size.height - 4.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, peakClampedY, barWidth, 3.0),
          const Radius.circular(1.5),
        ),
        peakPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
