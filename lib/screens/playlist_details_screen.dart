import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../providers/song_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_card.dart';
import '../core/constants/app_colors.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistDetailsScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch live playlist details from provider
    final livePlaylist = provider.playlists.firstWhere((p) => p.id == playlist.id, orElse: () => playlist);
    final songs = provider.allSongs.where((s) => livePlaylist.songIds.contains(s.id)).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (themed dynamically)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkBackground,
                        Colors.blueGrey.withValues(alpha: 0.1),
                        AppColors.darkBackground,
                      ]
                    : [
                        AppColors.lightBackground,
                        Colors.blueGrey.withValues(alpha: 0.15),
                        AppColors.lightBackground,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          livePlaylist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.playlist_add_circle_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 28),
                        onPressed: () => _showAddSongsToPlaylistDialog(context, provider, livePlaylist),
                      ),
                    ],
                  ),
                ),

                // Playlist Header Action Card (Play All, Shuffle)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (songs.isNotEmpty) {
                              provider.playSong(songs.first, songs, context: context);
                            }
                          },
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            borderRadius: 16,
                            color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.08),
                            borderColor: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: isDark ? Colors.white : Colors.black87),
                                const SizedBox(width: 8),
                                const Text("Play All", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (songs.isNotEmpty) {
                              // Enable shuffle mode and play
                              provider.toggleShuffle();
                              provider.playSong(songs[0], songs, context: context);
                            }
                          },
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            borderRadius: 16,
                            color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.08),
                            borderColor: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shuffle_rounded, color: isDark ? Colors.white : Colors.black87),
                                const SizedBox(width: 8),
                                const Text("Shuffle Play", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Songs List
                Expanded(
                  child: songs.isEmpty
                      ? _buildEmptyState()
                      : ReorderableListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 80),
                          itemCount: songs.length,
                          onReorder: (oldIndex, newIndex) {
                            provider.reorderSongsInPlaylist(livePlaylist.id, oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return Dismissible(
                              key: Key('playlist_item_${song.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                provider.removeSongFromPlaylist(livePlaylist.id, song.id);
                              },
                              child: SongCard(
                                song: song,
                                playlist: songs,
                              ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              "No tracks added to this playlist. Click the + icon at the top right to select tracks from your library.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog selecting library tracks to add to this playlist
  void _showAddSongsToPlaylistDialog(BuildContext context, SongProvider provider, PlaylistModel livePlaylist) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final availableSongs = provider.allSongs.where((s) => !livePlaylist.songIds.contains(s.id)).toList();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text("Add tracks to playlist", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (availableSongs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("All library tracks are already in this playlist.", style: TextStyle(color: Colors.grey)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: availableSongs.length,
                    itemBuilder: (context, index) {
                      final song = availableSongs[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.music_note_rounded, color: Colors.grey.withValues(alpha: 0.8)),
                        ),
                        title: Text(song.title),
                        subtitle: Text(song.artist),
                        onTap: () {
                          provider.addSongToPlaylist(livePlaylist.id, song.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
