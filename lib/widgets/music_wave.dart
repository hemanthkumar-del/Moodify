import 'dart:math';
import 'package:flutter/material.dart';

class MusicWave extends StatefulWidget {
  final Color color;
  final int barCount;
  final bool isPlaying;
  final double height;
  final double width;

  const MusicWave({
    Key? key,
    this.color = const Color(0xFF8B5CF6),
    this.barCount = 12,
    this.isPlaying = true,
    this.height = 40.0,
    this.width = 120.0,
  }) : super(key: key);

  @override
  State<MusicWave> createState() => _MusicWaveState();
}

class _MusicWaveState extends State<MusicWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Populate initial scale factors for each bar
    for (int i = 0; i < widget.barCount; i++) {
      _baseHeights.add(_random.nextDouble() * 0.6 + 0.4); // between 0.4 and 1.0
    }

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
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
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              // Calculate custom sinusoids for each bar to create a wavy flow
              double factor = 1.0;
              if (widget.isPlaying) {
                final double phase = (index / widget.barCount) * 2 * pi;
                factor = (sin(_controller.value * 2 * pi + phase) + 1) / 2; // 0.0 to 1.0
                factor = factor * 0.7 + 0.3; // scale to 0.3 - 1.0
              }

              final double currentHeight = widget.height * _baseHeights[index] * factor;

              return Container(
                width: (widget.width / widget.barCount) - 3,
                height: currentHeight.clamp(4.0, widget.height),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4.0),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
