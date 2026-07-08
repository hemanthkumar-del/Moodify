import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mood_model.dart';
import '../providers/song_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_card.dart';
import '../widgets/skeleton_loader.dart';
import 'song_details_screen.dart';
import '../core/utils/page_transitions.dart';
import '../core/constants/app_colors.dart';

class RecommendationScreen extends StatefulWidget {
  final MoodModel mood;

  const RecommendationScreen({
    Key? key,
    required this.mood,
  }) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  bool _showSkeleton = true;

  @override
  void initState() {
    super.initState();
    // Simulate content skeleton loader for 800ms to show loading transitions
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showSkeleton = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter recommended songs for this mood
    final songs = provider.recommendedSongs;

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
                        widget.mood.colors[1].withValues(alpha: 0.08),
                        AppColors.darkBackground,
                      ]
                    : [
                        AppColors.lightBackground,
                        widget.mood.colors[0].withValues(alpha: 0.12),
                        AppColors.lightBackground,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar (Back button, Title, Random Play Icon)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Text(
                        "${widget.mood.name} Tunes",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      // Mood randomizer playback button
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: widget.mood.colors[0],
                        ),
                        onPressed: () {
                          final song = provider.getRandomSongForMood(widget.mood.name);
                          if (song != null) {
                            provider.addToRecentlyPlayed(song);
                            Navigator.of(context).push(
                              FadeScalePageRoute(
                                page: SongDetailsScreen(song: song),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Large Mood Banner Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20.0),
                    borderRadius: 28.0,
                    child: Row(
                      children: [
                        // Large Mood Emoji
                        Text(
                          widget.mood.emoji,
                          style: const TextStyle(fontSize: 48),
                        )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.12, 1.12), duration: 1500.ms, curve: Curves.easeInOut),
                        const SizedBox(width: 20),
                        
                        // Mood Quote
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "DAILY VIBE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: widget.mood.colors[0],
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.mood.quote,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Scrollable Playlist Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Recommended Tracklist",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Recommended Songs List (with Shimmer effect)
                Expanded(
                  child: _showSkeleton
                      ? ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                children: [
                                  const SkeletonLoader(width: 70, height: 70, borderRadius: 16),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SkeletonLoader(width: 150, height: 16, borderRadius: 4),
                                        const SizedBox(height: 8),
                                        const SkeletonLoader(width: 90, height: 12, borderRadius: 4),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            return SongCard(
                              song: songs[index],
                              animateEntry: true,
                              playlist: songs,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
