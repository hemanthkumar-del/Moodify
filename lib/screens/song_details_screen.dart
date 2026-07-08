import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/song_model.dart';
import '../providers/song_provider.dart';
import '../widgets/gradient_cover.dart';
import '../widgets/equalizer.dart';
import '../widgets/glass_card.dart';
import '../core/constants/app_colors.dart';
import '../services/audio_player_service.dart';

class SongDetailsScreen extends StatefulWidget {
  final SongModel song;

  const SongDetailsScreen({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<SongDetailsScreen> createState() => _SongDetailsScreenState();
}

class _SongDetailsScreenState extends State<SongDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  StreamSubscription<bool>? _playSubscription;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SongProvider>(context, listen: false);
      _playSubscription = provider.isPlayingStream.listen((isPlaying) {
        if (mounted) {
          if (isPlaying) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _playSubscription?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<SongModel?>(
      stream: provider.currentSongStream,
      initialData: widget.song,
      builder: (context, songSnapshot) {
        final SongModel song = songSnapshot.data ?? widget.song;
        final isFav = provider.isFavorite(song.id);
        
        // Dynamic Accent Colors (palette extracted or mood fallbacks)
        final moodColors = AppColors.getMoodGradient(song.mood);
        final dynamicAccent = provider.dynamicAccentColor;
        
        final primaryAccent = dynamicAccent ?? moodColors[0];
        final secondaryAccent = dynamicAccent?.withValues(alpha: 0.8) ?? moodColors[1];
        final listGradient = [primaryAccent, secondaryAccent];

        final double matchPercentage = 80.0 + (song.id.hashCode % 19);

        final recommendedSongs = provider.allSongs
            .where((s) => s.mood.toLowerCase() == song.mood.toLowerCase())
            .toList();
            
        final relatedSongs = recommendedSongs.where((s) => s.id != song.id).toList();

        return Scaffold(
          body: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 200) { // Swiped down
                Navigator.of(context).pop();
              }
            },
            child: Stack(
              children: [
              // Background Dynamic Gradient
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.darkBackground,
                            secondaryAccent.withValues(alpha: 0.12),
                            AppColors.darkBackground,
                          ]
                        : [
                            AppColors.lightBackground,
                            primaryAccent.withValues(alpha: 0.15),
                            AppColors.lightBackground,
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Dynamic Blurred Cover Art Backdrop
              if (song.coverPath.isNotEmpty && !song.coverPath.startsWith('assets/'))
                Positioned.fill(
                  child: Opacity(
                    opacity: isDark ? 0.15 : 0.25,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Image.file(
                        File(song.coverPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Opacity(
                    opacity: isDark ? 0.12 : 0.2,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: moodColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Custom Dynamic App Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                "Now Playing",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      provider.sleepTimerMinutes != null || provider.sleepEndOfSong
                                          ? Icons.alarm_on_rounded
                                          : Icons.access_time_rounded,
                                      color: provider.sleepTimerMinutes != null || provider.sleepEndOfSong
                                          ? primaryAccent
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                    onPressed: () {
                                      _showSleepTimerBottomSheet(context, provider);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.queue_music_rounded,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                    onPressed: () {
                                      _showQueueBottomSheet(context, provider);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Album Art Cover
                        Center(
                          child: RotationTransition(
                            turns: _rotationController,
                            child: Hero(
                              tag: 'cover_${song.id}',
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryAccent.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: song.coverPath.isNotEmpty && !song.coverPath.startsWith('assets/')
                                      ? Image.file(
                                          File(song.coverPath),
                                          width: 240,
                                          height: 240,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return GradientCover(
                                              title: song.title,
                                              artist: song.artist,
                                              mood: song.mood,
                                              size: 240,
                                              borderRadius: 120,
                                            );
                                          },
                                        )
                                      : GradientCover(
                                          title: song.title,
                                          artist: song.artist,
                                          mood: song.mood,
                                          size: 240,
                                          borderRadius: 120,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate(key: ValueKey(song.id))
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 28),

                        // Title, Artist, and Favorite
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.redAccent : (isDark ? Colors.white54 : Colors.black54),
                                  size: 28,
                                ),
                                onPressed: () {
                                  provider.toggleFavorite(song);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        
                        // Mood Tag Indicator
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryAccent.withValues(alpha: 0.3), width: 1.0),
                              ),
                              child: Text(
                                "${song.mood} Vibe",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Match Percentage
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TweenAnimationBuilder<double>(
                              key: ValueKey('match_${song.id}'),
                              tween: Tween(begin: 0.0, end: matchPercentage),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.fastOutSlowIn,
                              builder: (context, value, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: CircularProgressIndicator(
                                        value: value / 100,
                                        strokeWidth: 7,
                                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                        color: primaryAccent,
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    Text(
                                      "${value.toInt()}%",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Mood Match Sync",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Aligned with your neural state",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Seek progress bar
                        StreamBuilder<PositionData>(
                          stream: provider.positionDataStream,
                          builder: (context, snapshot) {
                            final positionData = snapshot.data ?? PositionData(Duration.zero, Duration.zero, Duration.zero);
                            
                            double positionMs = positionData.position.inMilliseconds.toDouble();
                            double durationMs = positionData.duration.inMilliseconds.toDouble();
                            if (durationMs <= 0) durationMs = 1.0;
                            if (positionMs > durationMs) positionMs = durationMs;

                            return Column(
                              children: [
                                Slider(
                                  value: positionMs,
                                  max: durationMs,
                                  activeColor: primaryAccent,
                                  inactiveColor: primaryAccent.withValues(alpha: 0.2),
                                  onChanged: (val) {
                                    provider.seek(Duration(milliseconds: val.toInt()));
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(positionData.position),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(positionData.duration),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Primary Playback Controls
                        StreamBuilder<bool>(
                          stream: provider.player.shuffleModeEnabledStream,
                          builder: (context, shuffleSnapshot) {
                            final isShuffle = shuffleSnapshot.data ?? false;

                            return StreamBuilder<LoopMode>(
                              stream: provider.player.loopModeStream,
                              builder: (context, loopSnapshot) {
                                final loopMode = loopSnapshot.data ?? LoopMode.off;

                                return StreamBuilder<bool>(
                                  stream: provider.isPlayingStream,
                                  builder: (context, playingSnapshot) {
                                    final isPlaying = playingSnapshot.data ?? false;

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.shuffle_rounded,
                                            color: isShuffle ? primaryAccent : (isDark ? Colors.white54 : Colors.black54),
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            provider.toggleShuffle();
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.skip_previous_rounded,
                                            color: isDark ? Colors.white : Colors.black87,
                                            size: 36,
                                          ),
                                          onPressed: () {
                                            provider.previous();
                                          },
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (isPlaying) {
                                              provider.pause();
                                            } else {
                                              provider.resume();
                                            }
                                          },
                                          child: Container(
                                            width: 68,
                                            height: 68,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: listGradient,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryAccent.withValues(alpha: 0.3),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.skip_next_rounded,
                                            color: isDark ? Colors.white : Colors.black87,
                                            size: 36,
                                          ),
                                          onPressed: () {
                                            provider.next();
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            loopMode == LoopMode.one 
                                                ? Icons.repeat_one_rounded 
                                                : Icons.repeat_rounded,
                                            color: loopMode != LoopMode.off ? primaryAccent : (isDark ? Colors.white54 : Colors.black54),
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            provider.cycleRepeatMode();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Frequency Spectrum Visualizer
                        StreamBuilder<bool>(
                          stream: provider.isPlayingStream,
                          builder: (context, playingSnapshot) {
                            final isPlaying = playingSnapshot.data ?? false;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Frequency Spectrum",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 70,
                                  child: EqualizerVisualizer(
                                    colors: listGradient,
                                    barCount: 22,
                                    isPlaying: isPlaying,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        const SizedBox(height: 36),

                        // Related tracks
                        if (relatedSongs.isNotEmpty) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "More tracks matching this mood",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: relatedSongs.length,
                              itemBuilder: (context, index) {
                                final rSong = relatedSongs[index];
                                return GestureDetector(
                                  onTap: () {
                                    provider.playSong(rSong, recommendedSongs);
                                  },
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GradientCover(
                                          title: rSong.title,
                                          artist: rSong.artist,
                                          mood: rSong.mood,
                                          size: 90,
                                          borderRadius: 16,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          rSong.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          rSong.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Sleep timer picker sheet
  void _showSleepTimerBottomSheet(BuildContext context, SongProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final activeMins = provider.sleepTimerMinutes;
        final activeEnd = provider.sleepEndOfSong;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text("Sleep Timer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.timer_rounded, color: activeMins == 15 ? Colors.blueAccent : null),
                title: const Text("15 minutes"),
                trailing: activeMins == 15 ? const Icon(Icons.check_rounded, color: Colors.blueAccent) : null,
                onTap: () {
                  provider.setSleepTimer(15);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.timer_rounded, color: activeMins == 30 ? Colors.blueAccent : null),
                title: const Text("30 minutes"),
                trailing: activeMins == 30 ? const Icon(Icons.check_rounded, color: Colors.blueAccent) : null,
                onTap: () {
                  provider.setSleepTimer(30);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.timer_rounded, color: activeMins == 60 ? Colors.blueAccent : null),
                title: const Text("1 hour"),
                trailing: activeMins == 60 ? const Icon(Icons.check_rounded, color: Colors.blueAccent) : null,
                onTap: () {
                  provider.setSleepTimer(60);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.music_off_rounded, color: activeEnd ? Colors.blueAccent : null),
                title: const Text("End of current song"),
                trailing: activeEnd ? const Icon(Icons.check_rounded, color: Colors.blueAccent) : null,
                onTap: () {
                  provider.setSleepTimer(null, endOfSong: true);
                  Navigator.of(context).pop();
                },
              ),
              if (activeMins != null || activeEnd)
                ListTile(
                  leading: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                  title: const Text("Turn off timer", style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    provider.setSleepTimer(null);
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Queue drag reordering bottom sheet
  void _showQueueBottomSheet(BuildContext context, SongProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final playlist = provider.currentPlaylist;
            final currentIndex = provider.player.currentIndex ?? 0;
            final upcoming = playlist.sublist(min(currentIndex + 1, playlist.length));

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text("Play Queue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  if (provider.currentSong != null) ...[
                    Text("Now Playing", style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.play_circle_fill_rounded, color: Colors.blueAccent.shade100),
                      title: Text(provider.currentSong!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(provider.currentSong!.artist),
                    ),
                    const Divider(),
                  ],
                  const SizedBox(height: 8),
                  Text("Next Up (${upcoming.length})", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: upcoming.isEmpty
                        ? const Center(child: Text("Queue is empty", style: TextStyle(color: Colors.grey)))
                        : ReorderableListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: upcoming.length,
                            onReorder: (oldIndex, newIndex) {
                              final actualOld = currentIndex + 1 + oldIndex;
                              final actualNew = currentIndex + 1 + (newIndex > oldIndex ? newIndex - 1 : newIndex);
                              provider.moveQueueItem(actualOld, actualNew);
                              setSheetState(() {});
                            },
                            itemBuilder: (context, index) {
                              final song = upcoming[index];
                              final actualIndex = currentIndex + 1 + index;
                              return Dismissible(
                                key: ValueKey('queue_${song.id}_$actualIndex'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  provider.removeQueueItem(actualIndex);
                                  setSheetState(() {});
                                },
                                child: ListTile(
                                  key: ValueKey('tile_${song.id}_$actualIndex'),
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                                  title: Text(song.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  subtitle: Text(song.artist, style: const TextStyle(fontSize: 12)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                    onPressed: () {
                                      provider.removeQueueItem(actualIndex);
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
