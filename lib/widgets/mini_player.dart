import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../models/song_model.dart';
import 'gradient_cover.dart';
import 'glass_card.dart';
import '../screens/song_details_screen.dart';
import '../core/utils/page_transitions.dart';
import '../core/constants/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<SongModel?>(
      stream: provider.currentSongStream,
      builder: (context, snapshot) {
        final song = snapshot.data;
        if (song == null) {
          return const SizedBox.shrink(); // Hide mini player if no song is active
        }

        final moodColors = AppColors.getMoodGradient(song.mood);

        return StreamBuilder<bool>(
          stream: provider.isPlayingStream,
          builder: (context, playingSnapshot) {
            final isPlaying = playingSnapshot.data ?? false;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  FadeScalePageRoute(
                    page: SongDetailsScreen(song: song),
                  ),
                );
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -100) { // Swipe up
                  Navigator.of(context).push(
                    FadeScalePageRoute(
                      page: SongDetailsScreen(song: song),
                    ),
                  );
                }
              },
              child: Dismissible(
                key: Key('mini_player_${song.id}'),
                direction: DismissDirection.down,
                onDismissed: (_) {
                  provider.stop();
                },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  borderRadius: 24,
                  borderColor: moodColors[0].withValues(alpha: 0.3),
                  color: moodColors[1].withValues(alpha: isDark ? 0.15 : 0.08),
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        // Artwork
                        Hero(
                          tag: 'cover_${song.id}',
                          child: GradientCover(
                            title: song.title,
                            artist: song.artist,
                            mood: song.mood,
                            size: 48,
                            borderRadius: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Song Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Controls (Play/Pause, Next)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              iconSize: 28,
                              onPressed: () {
                                if (isPlaying) {
                                  provider.pause();
                                } else {
                                  provider.resume();
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              iconSize: 28,
                              onPressed: () {
                                provider.next();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
