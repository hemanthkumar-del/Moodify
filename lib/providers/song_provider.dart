import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart' as aq;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../services/song_service.dart';
import '../services/storage_service.dart';
import '../services/audio_player_service.dart';
import '../services/mood_engine.dart';

class SongProvider extends ChangeNotifier {
  final SongService _songService;
  final StorageService _storageService;
  final AudioPlayerService _audioService = AudioPlayerService();

  late Box<SongModel> _songsBox;
  late Box<PlaylistModel> _playlistsBox;

  List<SongModel> _allSongs = [];
  List<PlaylistModel> _playlists = [];
  List<String> _favoriteSongIds = [];
  List<String> _recentlyPlayedIds = [];
  List<String> _moodHistoryLogs = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedMood = '';
  bool _notificationsEnabled = true;

  // Trigger confetti state
  bool _showConfetti = false;

  // Sleep Timer variables
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;
  bool _sleepEndOfSong = false;

  // Dynamic Theme accent color
  Color? _dynamicAccentColor;

  bool _isAnalyzing = false;
  String _analysisStatus = '';

  int _lastSavedPosMs = 0;

  SongProvider(this._songService, this._storageService) {
    _notificationsEnabled = _storageService.isNotificationsEnabled();
    
    loadInitialData().then((_) {
      // Save position periodically (every 5 seconds)
      _audioService.player.positionStream.listen((pos) {
        final ms = pos.inMilliseconds;
        if ((ms - _lastSavedPosMs).abs() >= 5000) {
          _lastSavedPosMs = ms;
          _storageService.setLastPosition(ms);
        }
      });
    });

    // Listen to current song stream to handle dynamic states
    _audioService.currentSongStream.listen((song) {
      if (song != null) {
        _storageService.setLastSongId(song.id);
        _storageService.saveLastQueue(_audioService.currentPlaylist.map((s) => s.id).toList());
        addToRecentlyPlayed(song);
        updateDynamicAccent(song);
      }
    });
  }

  // Getters
  List<SongModel> get allSongs => _allSongs;
  List<PlaylistModel> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedMood => _selectedMood;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get showConfetti => _showConfetti;
  
  int? get sleepTimerMinutes => _sleepTimerMinutes;
  bool get sleepEndOfSong => _sleepEndOfSong;
  Color? get dynamicAccentColor => _dynamicAccentColor;
  bool get isAnalyzing => _isAnalyzing;
  String get analysisStatus => _analysisStatus;

  // Audio Service state accessors
  List<SongModel> get currentPlaylist => _audioService.currentPlaylist;
  SongModel? get currentSong => _audioService.currentSong;
  AudioPlayer get player => _audioService.player;
  
  Stream<SongModel?> get currentSongStream => _audioService.currentSongStream;
  Stream<bool> get isPlayingStream => _audioService.isPlayingStream;
  Stream<PositionData> get positionDataStream => _audioService.positionDataStream;
  Stream<int?> get currentIndexStream => _audioService.currentIndexStream;

  // Get favorite songs
  List<SongModel> get favoriteSongs {
    return _allSongs.where((song) => song.favorite).toList();
  }

  // Get recently played songs
  List<SongModel> get recentlyPlayedSongs {
    final List<SongModel> list = [];
    for (final id in _recentlyPlayedIds) {
      final song = _allSongs.firstWhere((s) => s.id == id, orElse: () => _allSongs.first);
      if (song.id == id && !list.contains(song)) {
        list.add(song);
      }
    }
    return list;
  }

  // Get list of recommended songs for the selected mood
  List<SongModel> get recommendedSongs {
    if (_selectedMood.isEmpty) return [];
    return _allSongs.where((song) => song.mood.toLowerCase() == _selectedMood.toLowerCase()).toList();
  }

  // Filter songs based on search query
  List<SongModel> get searchResults {
    if (_searchQuery.isEmpty) return _allSongs;
    final q = _searchQuery.toLowerCase();
    return _allSongs.where((song) {
      return song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q) ||
          song.album.toLowerCase().contains(q) ||
          song.mood.toLowerCase().contains(q) ||
          song.genre.toLowerCase().contains(q);
    }).toList();
  }

  // Statistics Computations
  int get totalListeningTimeSec {
    int totalSec = 0;
    for (var song in _allSongs) {
      if (song.playCount > 0) {
        final parts = song.duration.split(':');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts[1]) ?? 0;
          totalSec += (m * 60 + s) * song.playCount;
        }
      }
    }
    return totalSec;
  }

  String get favoriteGenre {
    if (_allSongs.isEmpty) return 'None';
    final Map<String, int> counts = {};
    for (var s in _allSongs) {
      counts[s.genre] = (counts[s.genre] ?? 0) + s.playCount;
    }
    String topGenre = 'None';
    int maxCount = -1;
    counts.forEach((key, val) {
      if (val > maxCount && val > 0) {
        maxCount = val;
        topGenre = key;
      }
    });
    return topGenre == 'None' ? (_allSongs.isNotEmpty ? _allSongs.first.genre : 'None') : topGenre;
  }

  String get favoriteMood {
    if (_allSongs.isEmpty) return 'None';
    final Map<String, int> counts = {};
    for (var s in _allSongs) {
      counts[s.mood] = (counts[s.mood] ?? 0) + s.playCount;
    }
    String topMood = 'None';
    int maxCount = -1;
    counts.forEach((key, val) {
      if (val > maxCount && val > 0) {
        maxCount = val;
        topMood = key;
      }
    });
    return topMood == 'None' ? (_allSongs.isNotEmpty ? _allSongs.first.mood : 'None') : topMood;
  }

  List<SongModel> get mostPlayedSongs {
    final list = _allSongs.where((s) => s.playCount > 0).toList();
    list.sort((a, b) => b.playCount.compareTo(a.playCount));
    return list.take(10).toList();
  }

  List<Map<String, String>> get moodHistory {
    return _moodHistoryLogs.map((log) {
      final parts = log.split('|');
      final moodName = parts[0];
      final timestampStr = parts.length > 1 ? parts[1] : DateTime.now().millisecondsSinceEpoch.toString();
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
      
      final timeStr = "${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

      return {
        'mood': moodName,
        'time': timeStr,
      };
    }).toList().reversed.toList();
  }

  // Load initial data from assets and storage
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    _songsBox = await Hive.openBox<SongModel>('songs');
    _playlistsBox = await Hive.openBox<PlaylistModel>('playlists');

    // Seeding sample tracks from songs.json if box is empty
    if (_songsBox.isEmpty) {
      final legacySongs = await _songService.loadSongs();
      for (final song in legacySongs) {
        await _songsBox.put(song.id, song);
      }
    }

    // Try to copy default assets locally and update database references
    await _copyAssetsToLocal();

    _allSongs = _songsBox.values.toList();
    _playlists = _playlistsBox.values.toList();

    _favoriteSongIds = _storageService.getFavorites();
    _recentlyPlayedIds = _storageService.getRecentlyPlayed();
    _moodHistoryLogs = _storageService.getMoodHistory();

    // Restore previous playback state
    try {
      final lastQueueIds = _storageService.getLastQueue();
      final lastSongId = _storageService.getLastSongId();
      final lastPosMs = _storageService.getLastPosition();

      if (lastQueueIds.isNotEmpty && lastSongId != null) {
        final List<SongModel> restoredQueue = [];
        for (final id in lastQueueIds) {
          final match = _allSongs.firstWhere((s) => s.id == id, orElse: () => _allSongs.first);
          if (match.id == id) restoredQueue.add(match);
        }
        
        final initialIndex = restoredQueue.indexWhere((s) => s.id == lastSongId);
        if (initialIndex != -1) {
          await _audioService.setPlaylist(restoredQueue, initialIndex);
          if (lastPosMs > 0) {
            await _audioService.seek(Duration(milliseconds: lastPosMs));
          }
        }
      }
    } catch (e) {
      debugPrint("Error restoring last playback state: $e");
    }

    // Sync smart mixes and run non-blocking background analysis on boot
    await updateSmartPlaylists();
    _analyzeAllUnanalyzedSongs();

    _isLoading = false;
    notifyListeners();
  }

  // Copy assets from bundle to local directory to satisfy local-only file playback
  Future<void> _copyAssetsToLocal() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      bool updatedAny = false;
      
      for (var song in _songsBox.values) {
        if (song.localPath.startsWith('assets/')) {
          final localDest = "${appDir.path}/${song.localPath}";
          final file = File(localDest);
          if (!await file.exists()) {
            try {
              await file.parent.create(recursive: true);
              final data = await rootBundle.load(song.localPath);
              final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
              await file.writeAsBytes(bytes);
              
              final updated = song.copyWith(localPath: localDest);
              await _songsBox.put(song.id, updated);
              updatedAny = true;
            } catch (e) {
              debugPrint("Asset not packaged: ${song.localPath}");
            }
          } else {
            final updated = song.copyWith(localPath: localDest);
            await _songsBox.put(song.id, updated);
            updatedAny = true;
          }
        }
      }
      
      if (updatedAny) {
        _allSongs = _songsBox.values.toList();
      }
    } catch (e) {
      debugPrint("Error copying default assets to local sandbox: $e");
    }
  }

  // Sync smart mixes/playlists dynamically in Hive
  Future<void> updateSmartPlaylists() async {
    try {
      final smartMixes = {
        'Happy Mix': ['happy'],
        'Workout Mix': ['workout', 'motivation', 'energetic'],
        'Relax Mix': ['relax', 'calm'],
        'Travel Mix': ['travel'],
        'Study Mix': ['study'],
        'Night Drive': ['party', 'romantic'],
        'Party Mix': ['party', 'energetic'],
      };

      for (var entry in smartMixes.entries) {
        final mixName = entry.key;
        final allowedMoods = entry.value;

        final matchedIds = _songsBox.values
            .where((s) => allowedMoods.contains(s.primaryMood.toLowerCase()) || 
                          allowedMoods.contains(s.secondaryMood.toLowerCase()))
            .map((s) => s.id)
            .toList();

        var playlist = _playlistsBox.values.firstWhere(
          (p) => p.name == mixName,
          orElse: () => PlaylistModel(
            id: 'smart_${mixName.replaceAll(" ", "_").toLowerCase()}',
            name: mixName,
            songIds: [],
          ),
        );

        final updated = playlist.copyWith(songIds: matchedIds);
        await _playlistsBox.put(playlist.id, updated);
      }

      // Sync Favorites Smart Mix
      final favIds = favoriteSongs.map((s) => s.id).toList();
      var favPlaylist = _playlistsBox.values.firstWhere(
        (p) => p.name == 'Favorites',
        orElse: () => PlaylistModel(
          id: 'smart_favorites',
          name: 'Favorites',
          songIds: [],
        ),
      );
      await _playlistsBox.put(favPlaylist.id, favPlaylist.copyWith(songIds: favIds));

      _playlists = _playlistsBox.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error syncing smart playlists: $e");
    }
  }

  // Background Mood Detection analysis task queue
  Future<void> _analyzeAllUnanalyzedSongs() async {
    final unanalyzed = _songsBox.values
        .where((s) => s.analyzedAt.isEmpty || s.analysisVersion != MoodEngine.currentVersion)
        .toList();
        
    if (unanalyzed.isEmpty) return;
    
    for (var song in unanalyzed) {
      await analyzeAndAssignMood(song);
    }
  }

  // Analyze single song and save classification
  Future<void> analyzeAndAssignMood(SongModel song) async {
    if (song.analyzedAt.isNotEmpty && song.analysisVersion == MoodEngine.currentVersion) {
      return;
    }

    _isAnalyzing = true;
    _analysisStatus = "Analyzing '${song.title}'...";
    notifyListeners();

    try {
      final result = await MoodEngine.analyzeSong(song);
      
      final updated = song.copyWith(
        primaryMood: result.primaryMood,
        secondaryMood: result.secondaryMood,
        confidence: result.confidence,
        analysisVersion: MoodEngine.currentVersion,
        analyzedAt: DateTime.now().toIso8601String(),
        bitrate: result.bitrate,
        sampleRate: result.sampleRate,
        mood: result.primaryMood,
      );

      await _songsBox.put(song.id, updated);
      _allSongs = _songsBox.values.toList();
      
      await updateSmartPlaylists();
      
      _analysisStatus = "Analysis Complete";
    } catch (e) {
      debugPrint("Error analyzing song mood: $e");
      _analysisStatus = "Analysis failed for '${song.title}'";
    } finally {
      _isAnalyzing = false;
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isAnalyzing && _analysisStatus == "Analysis Complete") {
          _analysisStatus = '';
          notifyListeners();
        }
      });
    }
  }

  // Manual User Mood Override updater
  Future<void> overrideSongMood(SongModel song, String newMood) async {
    final updated = song.copyWith(
      mood: newMood,
      primaryMood: newMood,
      confidence: 1.0,
      analyzedAt: DateTime.now().toIso8601String(),
    );
    await _songsBox.put(song.id, updated);
    _allSongs = _songsBox.values.toList();
    
    await updateSmartPlaylists();
    notifyListeners();
  }

  // Request storage/media permissions
  Future<bool> requestStoragePermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.audio,
    ].request();
    
    return statuses[Permission.audio] == PermissionStatus.granted ||
           statuses[Permission.storage] == PermissionStatus.granted;
  }

  // Scan device local audio storage
  Future<void> scanDeviceMusic() async {
    final allowed = await requestStoragePermission();
    if (!allowed) return;

    _isLoading = true;
    notifyListeners();

    try {
      final aq.OnAudioQuery audioQuery = aq.OnAudioQuery();
      final list = await audioQuery.querySongs(
        sortType: aq.SongSortType.TITLE,
        orderType: aq.OrderType.ASC_OR_SMALLER,
        uriType: aq.UriType.EXTERNAL,
      );

      for (var info in list) {
        final exists = _songsBox.values.any((s) => s.localPath == info.data);
        if (!exists && info.data.isNotEmpty) {
          final sec = ((info.duration ?? 0) / 1000).round();
          final min = (sec / 60).floor();
          final seconds = sec % 60;
          final durationStr = "$min:${seconds.toString().padLeft(2, '0')}";

          final newSong = SongModel(
            id: 'local_${info.id}',
            title: info.title,
            artist: info.artist ?? 'Unknown Artist',
            album: info.album ?? 'Unknown Album',
            genre: info.genre ?? 'Unknown Genre',
            duration: durationStr,
            mood: 'Relax',
            localPath: info.data,
            coverPath: '',
            favorite: false,
            playCount: 0,
            lastPlayed: '',
            dateAdded: DateTime.now().toIso8601String(),
          );
          await _songsBox.put(newSong.id, newSong);
        }
      }
      _allSongs = _songsBox.values.toList();
      _analyzeAllUnanalyzedSongs();
    } catch (e) {
      debugPrint("Error scanning device audio: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Picker import prep: copies audio to private docs folder, probes duration
  Future<SongModel?> pickAndPrepareSong() async {
    final allowed = await requestStoragePermission();
    if (!allowed) return null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'aac'],
    );

    if (result == null || result.files.single.path == null) return null;

    final File file = File(result.files.single.path!);
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = result.files.single.name;
    final localPath = '${appDir.path}/imported_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await file.copy(localPath);

    // Parse default metadata from name
    String title = fileName;
    if (title.contains('.')) {
      title = title.substring(0, title.lastIndexOf('.'));
    }
    String artist = "Unknown Artist";
    if (title.contains(' - ')) {
      final parts = title.split(' - ');
      artist = parts[0].trim();
      title = parts[1].trim();
    }

    // Probe duration using background AudioPlayer
    Duration duration = Duration.zero;
    final tempPlayer = AudioPlayer();
    try {
      final durationResult = await tempPlayer.setFilePath(localPath);
      if (durationResult != null) duration = durationResult;
    } catch (e) {
      debugPrint("Error probing duration: $e");
    } finally {
      await tempPlayer.dispose();
    }

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final durationStr = "$minutes:$seconds";

    return SongModel(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: artist,
      album: 'Unknown Album',
      genre: 'Unknown Genre',
      duration: durationStr,
      mood: 'Relax',
      localPath: localPath,
      coverPath: '',
      favorite: false,
      playCount: 0,
      lastPlayed: '',
      dateAdded: DateTime.now().toIso8601String(),
    );
  }

  // Save selected song info
  Future<void> saveImportedSong(SongModel song) async {
    await _songsBox.put(song.id, song);
    _allSongs = _songsBox.values.toList();
    notifyListeners();
    analyzeAndAssignMood(song);
  }

  // Long press edits song details
  Future<void> updateSongDetails(SongModel updated) async {
    await _songsBox.put(updated.id, updated);
    _allSongs = _songsBox.values.toList();
    await updateSmartPlaylists();
    notifyListeners();
  }

  // Deletes song metadata
  Future<void> deleteSong(SongModel song) async {
    await _songsBox.delete(song.id);
    _allSongs = _songsBox.values.toList();
    notifyListeners();
  }

  // User Playlist CRUD Operations
  Future<void> createPlaylist(String name) async {
    final playlist = PlaylistModel(
      id: 'playlist_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      songIds: [],
    );
    await _playlistsBox.put(playlist.id, playlist);
    _playlists = _playlistsBox.values.toList();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistsBox.delete(playlistId);
    _playlists = _playlistsBox.values.toList();
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final old = _playlistsBox.get(playlistId);
    if (old != null) {
      final updated = old.copyWith(name: newName);
      await _playlistsBox.put(playlistId, updated);
      _playlists = _playlistsBox.values.toList();
      notifyListeners();
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final old = _playlistsBox.get(playlistId);
    if (old != null) {
      if (!old.songIds.contains(songId)) {
        final updatedIds = List<String>.from(old.songIds)..add(songId);
        final updated = old.copyWith(songIds: updatedIds);
        await _playlistsBox.put(playlistId, updated);
        _playlists = _playlistsBox.values.toList();
        notifyListeners();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final old = _playlistsBox.get(playlistId);
    if (old != null) {
      final updatedIds = List<String>.from(old.songIds)..remove(songId);
      final updated = old.copyWith(songIds: updatedIds);
      await _playlistsBox.put(playlistId, updated);
      _playlists = _playlistsBox.values.toList();
      notifyListeners();
    }
  }

  // Plays a song within a given playlist with validation
  Future<bool> playSong(SongModel song, List<SongModel> playlist, {BuildContext? context}) async {
    // 1. Verify file exists
    final isAsset = song.localPath.startsWith('assets/');
    final file = File(song.localPath);
    final exists = isAsset ? false : await file.exists();

    if (!isAsset && !exists) {
      // 2. Remove invalid entry
      await deleteSong(song);
      
      // 3. Show proper error message
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("File not found: '${song.title}'. Removed from library."),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    try {
      final index = playlist.indexOf(song);
      if (index != -1) {
        await _audioService.setPlaylist(playlist, index);
        await _audioService.play();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error starting playback: $e");
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error playing audio: ${e.toString()}"),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  // Playback control interfaces
  Future<void> resume() async => await _audioService.play();
  Future<void> pause() async => await _audioService.pause();
  Future<void> stop() async => await _audioService.stop();
  Future<void> next() async => await _audioService.next();
  Future<void> previous() async => await _audioService.previous();
  Future<void> seek(Duration position) async => await _audioService.seek(position);

  Future<void> toggleShuffle() async {
    await _audioService.toggleShuffle();
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    await _audioService.cycleRepeatMode();
    notifyListeners();
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    await _audioService.moveQueueItem(oldIndex, newIndex);
    notifyListeners();
  }

  Future<void> removeQueueItem(int index) async {
    await _audioService.removeQueueItem(index);
    notifyListeners();
  }

  // Set selected mood and add to history
  void selectMood(String moodName) {
    _selectedMood = moodName;
    addMoodToHistory(moodName);
    notifyListeners();
  }

  // Add mood to history log
  Future<void> addMoodToHistory(String moodName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final log = "$moodName|$timestamp";
    _moodHistoryLogs.add(log);
    
    // Limit to last 20 history entries
    if (_moodHistoryLogs.length > 20) {
      _moodHistoryLogs.removeAt(0);
    }
    
    await _storageService.saveMoodHistory(_moodHistoryLogs);
    notifyListeners();
  }

  // Clear mood history
  Future<void> clearMoodHistory() async {
    _moodHistoryLogs.clear();
    await _storageService.saveMoodHistory(_moodHistoryLogs);
    notifyListeners();
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Check if song is favorited
  bool isFavorite(String songId) {
    final song = _songsBox.get(songId);
    return song?.favorite ?? false;
  }

  // Toggle favorite status
  Future<void> toggleFavorite(SongModel song) async {
    final current = _songsBox.get(song.id);
    if (current != null) {
      final updated = current.copyWith(favorite: !current.favorite);
      await _songsBox.put(song.id, updated);
      _allSongs = _songsBox.values.toList();
      
      if (updated.favorite) {
        triggerConfetti();
      }
      notifyListeners();
    }
  }

  // Trigger confetti animation
  void triggerConfetti() {
    _showConfetti = true;
    notifyListeners();
    // Reset after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _showConfetti = false;
      notifyListeners();
    });
  }

  // Add song to recently played list and increment statistics play count
  Future<void> addToRecentlyPlayed(SongModel song) async {
    _recentlyPlayedIds.remove(song.id);
    _recentlyPlayedIds.insert(0, song.id);
    if (_recentlyPlayedIds.length > 15) {
      _recentlyPlayedIds.removeLast();
    }
    await _storageService.saveRecentlyPlayed(_recentlyPlayedIds);

    final current = _songsBox.get(song.id);
    if (current != null) {
      final updated = current.copyWith(
        playCount: current.playCount + 1,
        lastPlayed: DateTime.now().toIso8601String(),
      );
      await _songsBox.put(song.id, updated);
      _allSongs = _songsBox.values.toList();
    }
    notifyListeners();
  }

  // Clear recently played
  Future<void> clearRecentlyPlayed() async {
    _recentlyPlayedIds.clear();
    await _storageService.saveRecentlyPlayed(_recentlyPlayedIds);
    notifyListeners();
  }

  // Get a random song recommended to user
  SongModel? getRandomSong() {
    if (_allSongs.isEmpty) return null;
    final random = Random();
    return _allSongs[random.nextInt(_allSongs.length)];
  }

  // Get a random song within the current mood
  SongModel? getRandomSongForMood(String mood) {
    final moodSongs = _allSongs.where((song) => song.mood.toLowerCase() == mood.toLowerCase()).toList();
    if (moodSongs.isEmpty) return null;
    final random = Random();
    return moodSongs[random.nextInt(moodSongs.length)];
  }

  // Toggle notifications setting
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _storageService.setNotificationsEnabled(value);
    notifyListeners();
  }

  // Sleep Timer controls
  void setSleepTimer(int? minutes, {bool endOfSong = false}) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    _sleepEndOfSong = endOfSong;

    if (minutes != null) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        pause();
        _sleepTimerMinutes = null;
        notifyListeners();
      });
    } else if (endOfSong) {
      // Setup a periodic check listener to pause at end of song
      _audioService.player.positionStream.listen((pos) {
        final duration = _audioService.player.duration ?? Duration.zero;
        if (pos >= duration && duration > Duration.zero && _sleepEndOfSong) {
          pause();
          _sleepEndOfSong = false;
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  // Extract accent colors using palette_generator
  Future<void> updateDynamicAccent(SongModel song) async {
    try {
      ImageProvider? imageProvider;
      if (song.coverPath.startsWith('assets/')) {
        imageProvider = AssetImage(song.coverPath);
      } else if (song.coverPath.isNotEmpty) {
        final file = File(song.coverPath);
        if (await file.exists()) {
          imageProvider = FileImage(file);
        }
      }

      if (imageProvider != null) {
        final palette = await PaletteGenerator.fromImageProvider(
          imageProvider,
          maximumColorCount: 10,
        );
        _dynamicAccentColor = palette.dominantColor?.color ?? palette.vibrantColor?.color;
        notifyListeners();
      } else {
        _dynamicAccentColor = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error generating palette: $e");
      _dynamicAccentColor = null;
      notifyListeners();
    }
  }

  // Database Backup
  Future<String?> backupDatabase() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/moodtunes_pro_backup.json');

      final Map<String, dynamic> data = {
        'songs': _songsBox.values.map((s) => s.toJson()).toList(),
        'playlists': _playlistsBox.values.map((p) => {
          'id': p.id,
          'name': p.name,
          'songIds': p.songIds,
        }).toList(),
      };

      await backupFile.writeAsString(jsonEncode(data));
      return backupFile.path;
    } catch (e) {
      debugPrint("Error backing up database: $e");
      return null;
    }
  }

  // Database Restore
  Future<bool> restoreDatabase() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/moodtunes_pro_backup.json');

      if (!await backupFile.exists()) return false;

      final String raw = await backupFile.readAsString();
      final Map<String, dynamic> data = jsonDecode(raw);

      await _songsBox.clear();
      await _playlistsBox.clear();

      final List songsList = data['songs'] as List;
      for (var sJson in songsList) {
        final song = SongModel(
          id: sJson['id'] as String,
          title: sJson['title'] as String,
          artist: sJson['artist'] as String,
          album: sJson['album'] as String,
          genre: sJson['genre'] as String,
          duration: sJson['duration'] as String,
          mood: sJson['mood'] as String,
          localPath: sJson['localPath'] as String,
          coverPath: sJson['coverPath'] as String,
          favorite: sJson['favorite'] as bool,
          playCount: sJson['playCount'] as int,
          lastPlayed: sJson['lastPlayed'] as String,
          dateAdded: sJson['dateAdded'] as String,
          primaryMood: sJson['primaryMood'] as String?,
          secondaryMood: sJson['secondaryMood'] as String?,
          confidence: (sJson['confidence'] as num?)?.toDouble(),
          analysisVersion: sJson['analysisVersion'] as int?,
          analyzedAt: sJson['analyzedAt'] as String?,
          bitrate: sJson['bitrate'] as int?,
          sampleRate: sJson['sampleRate'] as int?,
        );
        await _songsBox.put(song.id, song);
      }

      final List playlistsList = data['playlists'] as List;
      for (var pMap in playlistsList) {
        final playlist = PlaylistModel(
          id: pMap['id'] as String,
          name: pMap['name'] as String,
          songIds: List<String>.from(pMap['songIds'] as List),
        );
        await _playlistsBox.put(playlist.id, playlist);
      }

      _allSongs = _songsBox.values.toList();
      _playlists = _playlistsBox.values.toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error restoring database: $e");
      return false;
    }
  }

  // Launch URL helper
  Future<void> launchUrlString(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch $urlString: $e");
    }
  }
}
