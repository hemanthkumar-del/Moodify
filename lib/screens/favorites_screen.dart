import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/song_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/glass_card.dart';
import '../core/constants/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _favSearchController = TextEditingController();
  String _favQuery = '';
  String _favSortBy = 'Title';

  @override
  void initState() {
    super.initState();
    _favSearchController.addListener(() {
      setState(() {
        _favQuery = _favSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _favSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter favorites locally by query
    final favoriteSongsList = provider.favoriteSongs;
    final filteredFavorites = favoriteSongsList.where((song) {
      final q = _favQuery.toLowerCase();
      return song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q) ||
          song.genre.toLowerCase().contains(q);
    }).toList();

    switch (_favSortBy) {
      case 'Artist':
        filteredFavorites.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case 'Genre':
        filteredFavorites.sort((a, b) => a.genre.toLowerCase().compareTo(b.genre.toLowerCase()));
        break;
      case 'Date Added':
        filteredFavorites.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'Title':
      default:
        filteredFavorites.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

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
                    ? [AppColors.darkBackground, const Color(0xFF1E1318), AppColors.darkBackground]
                    : [AppColors.lightBackground, const Color(0xFFFDE8E8), AppColors.lightBackground],
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
                // Header Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                  child: Text(
                    "Favorite Tracks",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                
                // If there are favorites, show the local search bar
                if (favoriteSongsList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            borderRadius: 16,
                            child: TextField(
                              controller: _favSearchController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Filter favorites by title, artist...",
                                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                                prefixIcon: Icon(Icons.filter_list_rounded, color: isDark ? Colors.white54 : Colors.black45),
                                suffixIcon: _favSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _favSearchController.clear();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.sort_rounded, color: isDark ? Colors.white70 : Colors.black87),
                          onSelected: (val) {
                            setState(() {
                              _favSortBy = val;
                            });
                          },
                          itemBuilder: (context) => ['Title', 'Artist', 'Genre', 'Date Added'].map((val) {
                            return PopupMenuItem<String>(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: favoriteSongsList.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : (filteredFavorites.isEmpty
                          ? _buildNoResultsState(isDark)
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              itemCount: filteredFavorites.length,
                              itemBuilder: (context, index) {
                                return SongCard(
                                  song: filteredFavorites[index],
                                  animateEntry: true,
                                  playlist: filteredFavorites,
                                );
                              },
                            )),
                ),
                // Padding at bottom for BottomNav
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Heart Illustration
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 56,
                color: Colors.redAccent,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 1200.ms, curve: Curves.easeInOut),
            
            const SizedBox(height: 24),
            
            Text(
              "Your Favorites is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              "Start exploring moods and heart your favorite melodies. They will appear here completely offline!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Explore button
            GestureDetector(
              onTap: () {
                // Return to first page of IndexedStack (HomeScreen)
                // In main navigation, tab switches are handled by state. But since we are inside a tab, we can simply let user know or click home tab.
                // Wait! In main navigation screen, the tab index is inside the state of MainNavigationScreen.
                // If we want this button to switch tab, we can do it, but since we are just inside IndexedStack, let's recommend them to navigate using BottomNavigationBar. Or we can notify the user! Or we can show a SnackBar or just point it out.
                // Actually, let's give the button a nice action: pop back if they came from recommendation screen or show instructions.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tap the Home tab below to explore moods!"),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: const Text(
                  "Discover Music",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            "No matching favorites found",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
