import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyFavorites = 'favorite_songs';
  static const String _keyRecentlyPlayed = 'recently_played_songs';
  static const String _keyMoodHistory = 'mood_history';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyThemeAccent = 'theme_accent_color';

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Theme settings (true for dark, false for light)
  bool isDarkMode() {
    return _prefs?.getBool(_keyThemeMode) ?? true; // Dark by default
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(_keyThemeMode, value);
  }

  // Accent settings
  String getThemeAccent() {
    return _prefs?.getString(_keyThemeAccent) ?? 'violet';
  }

  Future<void> setThemeAccent(String value) async {
    await _prefs?.setString(_keyThemeAccent, value);
  }

  // Favorites
  List<String> getFavorites() {
    return _prefs?.getStringList(_keyFavorites) ?? [];
  }

  Future<void> saveFavorites(List<String> songIds) async {
    await _prefs?.setStringList(_keyFavorites, songIds);
  }

  // Recently Played
  List<String> getRecentlyPlayed() {
    return _prefs?.getStringList(_keyRecentlyPlayed) ?? [];
  }

  Future<void> saveRecentlyPlayed(List<String> songIds) async {
    await _prefs?.setStringList(_keyRecentlyPlayed, songIds);
  }

  // Mood History (stores mood selection logs formatted as "MoodName|timestamp_millis")
  List<String> getMoodHistory() {
    return _prefs?.getStringList(_keyMoodHistory) ?? [];
  }

  Future<void> saveMoodHistory(List<String> historyLogs) async {
    await _prefs?.setStringList(_keyMoodHistory, historyLogs);
  }

  // Notifications enabled
  bool isNotificationsEnabled() {
    return _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_keyNotificationsEnabled, value);
  }

  // Playback resume storage helpers
  static const String _keyLastSongId = 'last_played_song_id';
  static const String _keyLastPosition = 'last_playback_position';
  static const String _keyLastQueue = 'last_playlist_queue_ids';

  String? getLastSongId() {
    return _prefs?.getString(_keyLastSongId);
  }

  Future<void> setLastSongId(String value) async {
    await _prefs?.setString(_keyLastSongId, value);
  }

  int getLastPosition() {
    return _prefs?.getInt(_keyLastPosition) ?? 0;
  }

  Future<void> setLastPosition(int value) async {
    await _prefs?.setInt(_keyLastPosition, value);
  }

  List<String> getLastQueue() {
    return _prefs?.getStringList(_keyLastQueue) ?? [];
  }

  Future<void> saveLastQueue(List<String> queue) async {
    await _prefs?.setStringList(_keyLastQueue, queue);
  }
}
