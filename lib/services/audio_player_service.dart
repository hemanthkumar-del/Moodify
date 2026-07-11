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
    // Listen to active index changes to sync local subjects
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _currentPlaylist.length) {
        _currentIndex = index;
        _currentIndexSubject.add(_currentIndex);
        _currentSongSubject.add(_currentPlaylist[_currentIndex]);
      }
    });

    // Listen to player completion to advance queue automatically
    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        final isShuffle = _player.shuffleModeEnabled;
        final isLoopAll = _player.loopMode == LoopMode.all;
        final isLoopOne = _player.loopMode == LoopMode.one;

        if (isLoopOne) {
          await seek(Duration.zero);
          await play();
        } else if ((isShuffle && _currentPlaylist.length > 1) || isLoopAll || (_currentIndex + 1 < _currentPlaylist.length)) {
          await next();
        } else {
          // Reset when last song in the queue completes
          await stop();
          await seek(Duration.zero);
        }
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
        androidNotificationChannelName: 'Moodify Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
      );
      
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Audio focus handling (pause when interrupted, resume when gained back)
      bool shouldResumeOnFocusGain = false;

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.pause:
            case AudioInterruptionType.duck:
            case AudioInterruptionType.unknown:
              if (_instance.player.playing) {
                shouldResumeOnFocusGain = true;
                _instance.pause();
              }
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.pause:
            case AudioInterruptionType.duck:
            case AudioInterruptionType.unknown:
              if (shouldResumeOnFocusGain) {
                shouldResumeOnFocusGain = false;
                _instance.play();
              }
              break;
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

    final audioSources = _currentPlaylist.map((song) {
      final artUri = song.coverPath.startsWith('assets/')
          ? Uri.parse("asset:///${song.coverPath}")
          : (song.coverPath.isNotEmpty ? Uri.file(song.coverPath) : null);

      final tag = MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        artUri: artUri,
      );

      if (song.localPath.startsWith('assets/')) {
        return AudioSource.asset(song.localPath, tag: tag);
      } else {
        return AudioSource.file(song.localPath, tag: tag);
      }
    }).toList();

    try {
      final playlistSource = ConcatenatingAudioSource(children: audioSources);
      await _player.setAudioSource(playlistSource, initialIndex: initialIndex);
      
      _currentIndex = initialIndex;
      _currentIndexSubject.add(_currentIndex);
      _currentSongSubject.add(_currentPlaylist[_currentIndex]);
    } catch (e) {
      debugPrint("Error setting concatenating audio source: $e");
      await playAtIndex(initialIndex);
    }
  }

  // Play target index
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _currentPlaylist.length) return;
    final song = _currentPlaylist[index];

    // File validation check
    if (!song.localPath.startsWith('assets/')) {
      final file = File(song.localPath);
      if (!await file.exists()) {
        _currentIndexSubject.add(null);
        _currentSongSubject.add(null);
        throw FileNotFoundException("File not found: ${song.localPath}");
      }
    }

    _currentIndex = index;
    await _player.seek(Duration.zero, index: index);
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
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_player.loopMode == LoopMode.all && _currentPlaylist.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_player.loopMode == LoopMode.all && _currentPlaylist.isNotEmpty) {
      await _player.seek(Duration.zero, index: _currentPlaylist.length - 1);
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
