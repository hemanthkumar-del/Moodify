import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/song_provider.dart';
import '../widgets/glass_card.dart';
import '../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showScanLoader(BuildContext context, SongProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder(
          future: provider.scanDeviceMusic(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Device scanning finished successfully.")),
                );
              });
            }
            return Center(
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Scanning storage directories...", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final songProvider = Provider.of<SongProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
                    ? [AppColors.darkBackground, const Color(0xFF131A26), AppColors.darkBackground]
                    : [AppColors.lightBackground, const Color(0xFFE2E8F0), AppColors.lightBackground],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // SECTION 1: PREFERENCES
                    _buildSectionTitle("App Preferences", isDark),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      borderRadius: 24,
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            icon: Icons.dark_mode_rounded,
                            title: "Dark Theme",
                            subtitle: "Save eyes and battery life",
                            value: isDark,
                            onChanged: (val) {
                              themeProvider.toggleTheme();
                            },
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                          _buildSwitchRow(
                            icon: Icons.notifications_active_rounded,
                            title: "Music Recommendations",
                            subtitle: "Get notifications about matching songs",
                            value: songProvider.notificationsEnabled,
                            onChanged: (val) {
                              songProvider.toggleNotifications(val);
                            },
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.palette_rounded, color: isDark ? Colors.white70 : Colors.black54),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Theme Color",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Select your primary accent color",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildColorDot(context, themeProvider, 'violet', const Color(0xFF8B5CF6)),
                                    const SizedBox(width: 8),
                                    _buildColorDot(context, themeProvider, 'blue', const Color(0xFF3B82F6)),
                                    const SizedBox(width: 8),
                                    _buildColorDot(context, themeProvider, 'teal', const Color(0xFF14B8A6)),
                                    const SizedBox(width: 8),
                                    _buildColorDot(context, themeProvider, 'orange', const Color(0xFFF97316)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SECTION 2: PRO TOOLS & LOCAL STORAGE
                    _buildSectionTitle("Pro Settings & Storage", isDark),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      borderRadius: 24,
                      child: Column(
                        children: [
                          _buildClickableRow(
                            context: context,
                            icon: Icons.search_rounded,
                            title: "Scan Local Music",
                            subtitle: "Find audio tracks on phone storage",
                            onTap: () => _showScanLoader(context, songProvider),
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                          _buildClickableRow(
                            context: context,
                            icon: Icons.backup_rounded,
                            title: "Backup Database",
                            subtitle: "Save songs library & playlists state",
                            onTap: () async {
                              final path = await songProvider.backupDatabase();
                              if (path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Backup saved successfully to app documents folder.")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Error generating database backup.")),
                                );
                              }
                            },
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                          _buildClickableRow(
                            context: context,
                            icon: Icons.settings_backup_restore_rounded,
                            title: "Restore Database",
                            subtitle: "Load previously saved backup",
                            onTap: () async {
                              final success = await songProvider.restoreDatabase();
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Database restored successfully.")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No backup file found to restore.")),
                                );
                              }
                            },
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                          _buildInfoRow(
                            icon: Icons.folder_open_rounded,
                            title: "Storage Sandbox",
                            subtitle: "Internal app document directories",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SECTION 3: MOOD HISTORY LOGS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("Mood History Logs", isDark),
                        if (songProvider.moodHistory.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              songProvider.clearMoodHistory();
                            },
                            child: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                      ],
                    ),
                    
                    if (songProvider.moodHistory.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            "Your mood selection history is empty.",
                            style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(16),
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: songProvider.moodHistory.length,
                          itemBuilder: (context, index) {
                            final log = songProvider.moodHistory[index];
                            final isLast = index == songProvider.moodHistory.length - 1;
                            
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.history_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                                          const SizedBox(width: 8),
                                          Text(log['mood'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Text(
                                        log['time'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white30 : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast) Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
                              ],
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 28),

                    // SECTION 4: ABOUT PRO
                    _buildSectionTitle("About MoodTunes Pro", isDark),
                    GlassCard(
                      padding: const EdgeInsets.all(16.0),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.album_rounded, size: 36, color: Colors.blueAccent.shade100),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("MoodTunes Pro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("Version 2.0.0 (Build 200)", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "An award-winning premium offline audio player. Imports, organizes, and queries device tracks by mood using intelligent localized engines.",
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("© 2026 DeepMind Antigravity Team.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  showLicensePage(
                                    context: context,
                                    applicationName: "MoodTunes Pro",
                                    applicationVersion: "2.0.0",
                                    applicationIcon: Icon(Icons.album_rounded, size: 48, color: themeProvider.primaryAccent),
                                  );
                                },
                                icon: const Icon(Icons.description_rounded, size: 14),
                                label: const Text("Licenses", style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(BuildContext context, ThemeProvider themeProvider, String value, Color color) {
    final isSelected = themeProvider.themeAccent.toLowerCase() == value;
    return GestureDetector(
      onTap: () {
        themeProvider.setThemeAccent(value);
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white30 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
