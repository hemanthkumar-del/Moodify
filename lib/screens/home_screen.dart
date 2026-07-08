import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/song_provider.dart';
import '../providers/theme_provider.dart';
import '../models/mood_model.dart';
import '../models/song_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_card.dart';
import '../widgets/gradient_cover.dart';
import 'loading_screen.dart';
import 'song_details_screen.dart';
import '../core/utils/page_transitions.dart';
import '../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  late String _dailyQuote;

  final List<String> _quotesList = [
    "Where words fail, music speaks. — Hans Christian Andersen",
    "Music can change the world because it can change people. — Bono",
    "One good thing about music, when it hits you, you feel no pain. — Bob Marley",
    "Music is the shorthand of emotion. — Leo Tolstoy",
    "Life is one grand sweet song, so start the music. — Ronald Reagan",
    "Music is a moral law. It gives soul to the universe, wings to the mind. — Plato",
  ];

  @override
  void initState() {
    super.initState();
    _dailyQuote = _quotesList[DateTime.now().day % _quotesList.length];
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    final provider = Provider.of<SongProvider>(context, listen: false);
    provider.updateSearchQuery(query);
    setState(() {
      _isSearching = query.isNotEmpty || _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatListeningTime(int sec) {
    if (sec < 60) return "$sec s";
    final min = (sec / 60).round();
    if (min < 60) return "$min mins";
    final hr = (min / 60).toStringAsFixed(1);
    return "$hr hrs";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final songs = provider.allSongs;
    final searchSongs = provider.searchResults;

    // Moods static configurations
    final moods = MoodModel.allMoods;

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
                    ? [AppColors.darkBackground, const Color(0xFF131320), AppColors.darkBackground]
                    : [AppColors.lightBackground, const Color(0xFFEEF2F6), AppColors.lightBackground],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header (Greeting & Theme Toggle)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "MoodTunes Pro",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          onPressed: () {
                            themeProvider.toggleTheme();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar Input
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      borderRadius: 20,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: "Search track name, artist, genre...",
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                          border: InputBorder.none,
                          icon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : Colors.black87),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchFocusNode.unfocus();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Search result output if active
                if (_isSearching) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "Search Results (${searchSongs.length})",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (searchSongs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          "No tracks match your query.",
                          style: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return SongCard(
                              song: searchSongs[index],
                              playlist: searchSongs,
                            );
                          },
                          childCount: searchSongs.length,
                        ),
                      ),
                    ),
                ] else ...[
                  // Dynamic Daily Quote
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 20,
                        child: Row(
                          children: [
                            Icon(Icons.format_quote_rounded, size: 28, color: Colors.blueAccent.withValues(alpha: 0.8)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dailyQuote,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Premium Statistics Workspace
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Weekly Analytics",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GlassCard(
                                  padding: const EdgeInsets.all(12),
                                  borderRadius: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Listening Time", style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black38)),
                                      const SizedBox(height: 6),
                                      Text(_formatListeningTime(provider.totalListeningTimeSec), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GlassCard(
                                  padding: const EdgeInsets.all(12),
                                  borderRadius: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Top Vibe", style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black38)),
                                      const SizedBox(height: 6),
                                      Text(provider.favoriteMood, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Continue Listening (Last Played Track)
                  if (provider.currentSong != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Continue Listening",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  FadeScalePageRoute(
                                    page: SongDetailsScreen(song: provider.currentSong!),
                                  ),
                                );
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                borderRadius: 20,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: GradientCover(
                                        title: provider.currentSong!.title,
                                        artist: provider.currentSong!.artist,
                                        mood: provider.currentSong!.mood,
                                        size: 60,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(provider.currentSong!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(provider.currentSong!.artist, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.play_circle_fill_rounded, color: isDark ? Colors.white : Colors.black87, size: 36),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Quick Play (Random Launcher)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: GestureDetector(
                        onTap: () {
                          final rand = provider.getRandomSong();
                          if (rand != null) {
                            provider.playSong(rand, provider.allSongs);
                            Navigator.of(context).push(
                              FadeScalePageRoute(
                                page: SongDetailsScreen(song: rand),
                              ),
                            );
                          }
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: 20,
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderColor: Colors.deepPurple.withValues(alpha: 0.3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shuffle_rounded, color: Colors.purpleAccent.shade100),
                              const SizedBox(width: 12),
                              const Text("Quick Play Random Song", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Recently Played tracks
                  if (provider.recentlyPlayedSongs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                            child: Text(
                              "Recently Played",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: provider.recentlyPlayedSongs.length,
                              itemBuilder: (context, index) {
                                final rSong = provider.recentlyPlayedSongs[index];
                                return GestureDetector(
                                  onTap: () {
                                    provider.playSong(rSong, provider.recentlyPlayedSongs);
                                    Navigator.of(context).push(
                                      FadeScalePageRoute(
                                        page: SongDetailsScreen(song: rSong),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: GradientCover(
                                            title: rSong.title,
                                            artist: rSong.artist,
                                            mood: rSong.mood,
                                            size: 90,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(rSong.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        Text(rSong.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: isDark ? Colors.white60 : Colors.black54)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Mood Cards Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Select Mood Vibe",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${moods.length} Vibes",
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mood = moods[index];
                          final colors = AppColors.getMoodGradient(mood.name);

                          return GestureDetector(
                            onTap: () {
                              provider.selectMood(mood.name);
                              Navigator.of(context).push(
                                FadeScalePageRoute(
                                  page: LoadingScreen(mood: mood),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors[0].withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -10,
                                    bottom: -10,
                                    child: Opacity(
                                      opacity: 0.15,
                                      child: Text(
                                        mood.emoji,
                                        style: const TextStyle(fontSize: 64),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          mood.emoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        Text(
                                          mood.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: moods.length,
                      ),
                    ),
                  ),

                  // Most Played (from storage statistics)
                  if (provider.mostPlayedSongs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                            child: Text(
                              "Most Played Tracks",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: min(5, provider.mostPlayedSongs.length),
                            itemBuilder: (context, index) {
                              final song = provider.mostPlayedSongs[index];
                              return SongCard(
                                song: song,
                                playlist: provider.mostPlayedSongs,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  // Favorites Section
                  if (provider.favoriteSongs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                            child: Text(
                              "Your Favorites",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: min(5, provider.favoriteSongs.length),
                            itemBuilder: (context, index) {
                              final song = provider.favoriteSongs[index];
                              return SongCard(
                                song: song,
                                playlist: provider.favoriteSongs,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  // Bottom spacer for BottomNav
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
