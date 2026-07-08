import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F12);
  static const Color darkSurface = Color(0xFF181824);
  static const Color darkSurfaceLow = Color(0xFF12121A);
  static const Color darkCard = Color(0x1AFFFFFF); // Glassmorphism container
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLow = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0x1F000000); // Glassmorphism container
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Core Theme Accents
  static const Color primary = Color(0xFF8B5CF6); // Premium Violet
  static const Color secondary = Color(0xFF3B82F6); // Electric Blue
  static const Color accent = Color(0xFFEC4899); // Rose Pink
  static const Color favorite = Color(0xFFEF4444); // Crimson Red

  // Glassmorphic Borders
  static const Color darkGlassBorder = Color(0x33FFFFFF);
  static const Color lightGlassBorder = Color(0x1F000000);

  // Mood Gradients (Aesthetic start and end colors)
  static const List<Color> happyGradient = [Color(0xFFFBBF24), Color(0xFFF59E0B)]; // Warm gold
  static const List<Color> sadGradient = [Color(0xFF3B82F6), Color(0xFF1D4ED8)]; // Ocean blue
  static const List<Color> relaxGradient = [Color(0xFF14B8A6), Color(0xFF0F766E)]; // Calm teal
  static const List<Color> workoutGradient = [Color(0xFFEF4444), Color(0xFFB91C1C)]; // Intense red
  static const List<Color> romanticGradient = [Color(0xFFEC4899), Color(0xFFBE185D)]; // Sweet rose
  static const List<Color> lonelyGradient = [Color(0xFF6B7280), Color(0xFF374151)]; // Slate grey
  static const List<Color> studyGradient = [Color(0xFF6366F1), Color(0xFF4338CA)]; // Deep indigo
  static const List<Color> sleepGradient = [Color(0xFF1E1B4B), Color(0xFF311042)]; // Midnight purple

  static List<Color> getMoodGradient(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return happyGradient;
      case 'sad':
        return sadGradient;
      case 'relax':
        return relaxGradient;
      case 'workout':
        return workoutGradient;
      case 'romantic':
        return romanticGradient;
      case 'lonely':
        return lonelyGradient;
      case 'study':
        return studyGradient;
      case 'sleep':
        return sleepGradient;
      default:
        return [primary, secondary];
    }
  }
}
