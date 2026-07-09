import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import '../models/song_model.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlayerService {
  // Singleton instance
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _currentPlaylist = [];
  int _currentIndex = 0;

  // BehaviorSubjects to broadcast current song and index safely
  final BehaviorSubject<int?> _currentIndexSubject = BehaviorSubject<int?>.seeded(null);
  final BehaviorSubject<SongModel?> _currentSongSubject = BehaviorSubject<SongModel?>.seeded(null);

  // Constructor
  AudioPlayerService._internal() {
    // Listen to player completion to advance queue automatically
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        next();
      }
    });
  }

  // Getters
  AudioPlayer get player => _player;
  List<SongModel> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  
  SongModel? get currentSong => _currentSongSubject.value;

  // Streams for UI updates
  Stream<int?> get currentIndexStream => _currentIndexSubject.stream;
  Stream<SongModel?> get currentSongStream => _currentSongSubject.stream;
  Stream<bool> get isPlayingStream => _player.playingStream;

  // Initialize background settings and audio focus sessions
  static Future<void> initBackground() async {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.moodtunes.pro.channel.audio',
        androidNotificationChannelName: 'MoodTunes Pro Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
      );
      
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Audio focus handling (pause when interrupted)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.pause:
            case AudioInterruptionType.duck:
              _instance.pause();
              break;
            default:
              break;
          }
        } else {
          if (event.type == AudioInterruptionType.duck) {
            _instance.play();
          }
        }
      });

      // Pause when headphones are unplugged
      session.becomingNoisyEventStream.listen((_) {
        _instance.pause();
      });

    } catch (e) {
      debugPrint("Error initializing AudioSession/Background: $e");
    }
  }

  // Set the playlist queue and load the track
  Future<void> setPlaylist(List<SongModel> songs, int initialIndex) async {
    if (songs.isEmpty) return;
    _currentPlaylist = List<SongModel>.from(songs);
    await playAtIndex(initialIndex);
  }

  // Play target index using setFilePath
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _currentPlaylist.length) return;
    _currentIndex = index;
    final song = _currentPlaylist[index];

    // File validation check
    if (!song.localPath.startsWith('assets/')) {
      final file = File(song.localPath);
      if (!await file.exists()) {
        // Broadcast error and remove from index state
        _currentIndexSubject.add(null);
        _currentSongSubject.add(null);
        throw FileNotFoundException("File not found: ${song.localPath}");
      }
    }

    final artUri = song.coverPath.startsWith('assets/')
        ? Uri.parse("asset:///${song.coverPath}")
        : (song.coverPath.isNotEmpty ? Uri.file(song.coverPath) : null);

    try {
      // Load file using setFilePath
      await _player.setFilePath(
        song.localPath,
        tag: MediaItem(
          id: song.id,
          album: song.album,
          title: song.title,
          artist: song.artist,
          artUri: artUri,
        ),
      );
      
      // Update subjects to trigger stream listeners
      _currentIndexSubject.add(_currentIndex);
      _currentSongSubject.add(song);
    } catch (e) {
      debugPrint("Error loading file path in player: $e");
      // Broadcast null state and skip gracefully if in playlist
      _currentIndexSubject.add(null);
      _currentSongSubject.add(null);
      throw Exception("Codec / Audio format not supported: $e");
    }
  }

  // Queue manipulation
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex >= 0 && newIndex >= 0 && oldIndex < _currentPlaylist.length && newIndex < _currentPlaylist.length) {
      final item = _currentPlaylist.removeAt(oldIndex);
      _currentPlaylist.insert(newIndex, item);
      
      if (_currentIndex == oldIndex) {
        _currentIndex = newIndex;
        _currentIndexSubject.add(_currentIndex);
      } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
        _currentIndex--;
        _currentIndexSubject.add(_currentIndex);
      } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
        _currentIndex++;
        _currentIndexSubject.add(_currentIndex);
      }
    }
  }

  Future<void> removeQueueItem(int index) async {
    if (index >= 0 && index < _currentPlaylist.length) {
      _currentPlaylist.removeAt(index);
      
      if (_currentIndex == index) {
        if (_currentPlaylist.isEmpty) {
          await stop();
          _currentIndexSubject.add(null);
          _currentSongSubject.add(null);
        } else {
          if (_currentIndex >= _currentPlaylist.length) {
            _currentIndex = 0;
          }
          await playAtIndex(_currentIndex);
          await play();
        }
      } else if (_currentIndex > index) {
        _currentIndex--;
        _currentIndexSubject.add(_currentIndex);
      }
    }
  }

  // Playback Control Methods
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position, {int? index}) async {
    if (index != null && index != _currentIndex) {
      await playAtIndex(index);
    }
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_currentPlaylist.isEmpty) return;
    int nextIndex = _currentIndex + 1;
    if (_player.shuffleModeEnabled) {
      nextIndex = Random().nextInt(_currentPlaylist.length);
    }
    if (nextIndex < _currentPlaylist.length) {
      try {
        await playAtIndex(nextIndex);
        await play();
      } catch (e) {
        // Skip current unsupported and advance again
        await next();
      }
    } else if (_player.loopMode == LoopMode.all) {
      try {
        await playAtIndex(0);
        await play();
      } catch (e) {
        await next();
      }
    }
  }

  Future<void> previous() async {
    if (_currentPlaylist.isEmpty) return;
    int prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
      try {
        await playAtIndex(prevIndex);
        await play();
      } catch (e) {
        await previous();
      }
    } else if (_player.loopMode == LoopMode.all) {
      try {
        await playAtIndex(_currentPlaylist.length - 1);
        await play();
      } catch (e) {
        await previous();
      }
    }
  }

  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(enable);
  }

  Future<void> cycleRepeatMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  // Stream getter combining current position, buffered duration, and total duration
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => message;
}
