import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/mini_player.dart';
import '../providers/song_provider.dart';
import '../core/constants/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);

    return Scaffold(
      extendBody: true, // Allows content to flow behind navigation bar
      body: ConfettiOverlay(
        show: provider.showConfetti,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.analysisStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  borderRadius: 16,
                  color: (provider.isAnalyzing ? Colors.blue : Colors.green).withValues(alpha: 0.1),
                  borderColor: (provider.isAnalyzing ? Colors.blue : Colors.green).withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      if (provider.isAnalyzing)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      else
                        Icon(
                          provider.analysisStatus.contains('failed') ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                          color: provider.analysisStatus.contains('failed') ? Colors.red : Colors.green,
                          size: 16,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.analysisStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: provider.isAnalyzing
                                ? Colors.blue
                                : (provider.analysisStatus.contains('failed') ? Colors.red : Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: MiniPlayer(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                borderRadius: 30,
                blur: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, "Home"),
                    _buildNavItem(1, Icons.library_music_rounded, "Library"),
                    _buildNavItem(2, Icons.favorite_rounded, "Favorites"),
                    _buildNavItem(3, Icons.settings_rounded, "Settings"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white30 : Colors.black26),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white30 : Colors.black26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
