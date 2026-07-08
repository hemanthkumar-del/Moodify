import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MoodModel {
  final String name;
  final String emoji;
  final String description;
  final String quote;

  MoodModel({
    required this.name,
    required this.emoji,
    required this.description,
    required this.quote,
  });

  List<Color> get colors => AppColors.getMoodGradient(name);

  static List<MoodModel> get allMoods => [
        MoodModel(
          name: "Happy",
          emoji: "😊",
          description: "Full of energy & smiles",
          quote: "Happiness is not something ready-made. It comes from your own actions.",
        ),
        MoodModel(
          name: "Sad",
          emoji: "😢",
          description: "Feeling low & blue",
          quote: "Tears are words the heart can't say. Let the music speak.",
        ),
        MoodModel(
          name: "Relax",
          emoji: "😌",
          description: "Calm, peaceful & quiet",
          quote: "Quiet the mind and the soul will speak. Breathe in, breathe out.",
        ),
        MoodModel(
          name: "Workout",
          emoji: "🔥",
          description: "Ready to push limits",
          quote: "Your body can stand almost anything. It's your mind that you have to convince.",
        ),
        MoodModel(
          name: "Romantic",
          emoji: "❤️",
          description: "In the mood for love",
          quote: "Love is composed of a single soul inhabiting two bodies.",
        ),
        MoodModel(
          name: "Lonely",
          emoji: "🌧",
          description: "Alone in a quiet space",
          quote: "Sometimes you need to stand alone just to see who will stand beside you.",
        ),
        MoodModel(
          name: "Study",
          emoji: "📚",
          description: "Deep focus & learning",
          quote: "Focus on the journey, not the destination. Success starts here.",
        ),
        MoodModel(
          name: "Sleep",
          emoji: "🌙",
          description: "Drifting into dreams",
          quote: "Sleep is the best meditation. Rest your mind, tomorrow is a new day.",
        ),
      ];
}
