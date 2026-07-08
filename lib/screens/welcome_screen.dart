import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/page_transitions.dart';
import 'main_navigation_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkBackground,
                        const Color(0xFF1E1B4B),
                        AppColors.darkBackground,
                      ]
                    : [
                        AppColors.lightBackground,
                        const Color(0xFFEEF2F6),
                        AppColors.lightBackground,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Premium Dynamic Graphic in background/center
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring 1
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        width: 2,
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2500.ms, curve: Curves.easeInOut),
                  
                  // Pulse ring 2
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 2000.ms, curve: Curves.easeInOut),

                  // Floating musical notes
                  const Positioned(
                    top: 40,
                    left: 60,
                    child: Icon(Icons.music_note_rounded, size: 40, color: AppColors.primary),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .slideY(begin: 0.15, end: -0.15, duration: 1500.ms, curve: Curves.easeInOut)
                  .fadeIn(duration: 800.ms),

                  const Positioned(
                    bottom: 50,
                    right: 70,
                    child: Icon(Icons.library_music_rounded, size: 36, color: AppColors.accent),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .slideY(begin: -0.2, end: 0.2, duration: 1800.ms, curve: Curves.easeInOut)
                  .fadeIn(duration: 800.ms),
                  
                  // Center geometric illustration
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.headphones_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .rotate(begin: -0.05, end: 0.05, duration: 3000.ms, curve: Curves.easeInOut),
                ],
              ),
            ),
          ),
          
          // Text Contents & Start Button at bottom
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  "MoodTunes AI",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0.0, duration: 600.ms, curve: Curves.easeOutCubic),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  "Your mood. Your music.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0.0, delay: 200.ms, duration: 600.ms, curve: Curves.easeOutCubic),
                
                const SizedBox(height: 48),
                
                // Animated Start Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      FadeScalePageRoute(
                        page: const MainNavigationScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02), duration: 1500.ms, curve: Curves.easeInOut),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.4, end: 0.0, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
