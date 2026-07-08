import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mood_model.dart';
import '../widgets/equalizer.dart';
import 'recommendation_screen.dart';
import '../core/utils/page_transitions.dart';

class LoadingScreen extends StatefulWidget {
  final MoodModel mood;

  const LoadingScreen({
    Key? key,
    required this.mood,
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Simulate analyzing mood for 2.5 seconds, then open recommendations
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          FadeScalePageRoute(
            page: RecommendationScreen(mood: widget.mood),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? Colors.black : Colors.white,
              widget.mood.colors[0].withValues(alpha: isDark ? 0.15 : 0.25),
              isDark ? Colors.black : Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating Mood Emoji
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.mood.colors[0].withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.mood.colors[0].withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.mood.colors[1].withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.mood.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            )
            .animate()
            .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.elasticOut)
            .then()
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 1000.ms, curve: Curves.easeInOut),

            const SizedBox(height: 48),

            // Animated Equalizer Visualizer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: SizedBox(
                height: 100,
                child: EqualizerVisualizer(
                  colors: widget.mood.colors,
                  barCount: 16,
                  isPlaying: true,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Shifting Text Kit
            SizedBox(
              height: 40,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                  letterSpacing: 0.5,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    FadeAnimatedText("Analyzing your mood..."),
                    FadeAnimatedText("Translating emotions into frequencies..."),
                    FadeAnimatedText("Tuning local offline frequencies..."),
                    FadeAnimatedText("Almost ready to launch!"),
                  ],
                  pause: const Duration(milliseconds: 200),
                  isRepeatingAnimation: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
