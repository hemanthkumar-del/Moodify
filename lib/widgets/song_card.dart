import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/song_model.dart';
import '../providers/song_provider.dart';
import 'gradient_cover.dart';
import 'glass_card.dart';
import '../screens/song_details_screen.dart';
import '../core/utils/page_transitions.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final bool animateEntry;
  final List<SongModel>? playlist;

  const SongCard({
    Key? key,
    required this.song,
    this.animateEntry = true,
    this.playlist,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final isFav = provider.isFavorite(song.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = GestureDetector(
      onTap: () {
        provider.playSong(song, playlist ?? [song]);
        
        Navigator.of(context).push(
          FadeScalePageRoute(
            page: SongDetailsScreen(song: song),
          ),
        );
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(12.0),
        borderRadius: 20.0,
        child: Row(
          children: [
            // Album Artwork (Hero animation key is song.id)
            Hero(
              tag: 'cover_${song.id}',
              child: GradientCover(
                title: song.title,
                artist: song.artist,
                mood: song.mood,
                size: 70,
                borderRadius: 16,
              ),
            ),
            const SizedBox(width: 16),
            
            // Song Details (Title, Artist, Genre/Duration)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          song.genre,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        song.duration,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Actions: Spotify, YouTube, Favorite
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Favorite Toggle Button
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : (isDark ? Colors.white30 : Colors.black38),
                    size: 24,
                  ),
                  onPressed: () {
                    provider.toggleFavorite(song);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (animateEntry) {
      return card
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.15, end: 0.0, duration: 400.ms, curve: Curves.easeOutCubic);
    }
    
    return card;
  }
}
