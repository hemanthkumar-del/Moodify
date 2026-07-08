import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../widgets/music_wave.dart';
import 'welcome_screen.dart';
import '../core/utils/page_transitions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto navigation after 2.5 seconds (giving animations time to complete)
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          FadeScalePageRoute(page: const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.darkBackground,
              Color(0xFF1E1B4B), // Midnight Blue
              AppColors.darkBackground,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Logo Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 72,
                color: Colors.white,
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              "MoodTunes AI",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0.0, delay: 300.ms, duration: 600.ms, curve: Curves.easeOutCubic),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              "Your mood. Your music.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 600.ms),
            
            const Spacer(),
            
            // Music wave animation at bottom
            const MusicWave(
              color: AppColors.primary,
              barCount: 16,
              height: 50,
              width: 160,
              isPlaying: true,
            )
            .animate()
            .fadeIn(delay: 700.ms, duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), delay: 700.ms, duration: 600.ms),
            
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
