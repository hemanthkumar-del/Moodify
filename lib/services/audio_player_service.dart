import 'dart:io';
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
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _currentPlaylist = [];
  ConcatenatingAudioSource? _playlistSource;

  // Getters
  AudioPlayer get player => _player;
  List<SongModel> get currentPlaylist => _currentPlaylist;
  
  SongModel? get currentSong {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _currentPlaylist.length) return null;
    return _currentPlaylist[index];
  }

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
    _currentPlaylist = List<SongModel>.from(songs);
    
    final List<AudioSource> sources = [];
    for (var song in songs) {
      final isAsset = song.localPath.startsWith('assets/');
      
      final artUri = song.coverPath.startsWith('assets/')
          ? Uri.parse("asset:///${song.coverPath}")
          : (song.coverPath.isNotEmpty ? Uri.file(song.coverPath) : null);

      if (isAsset) {
        sources.add(
          AudioSource.asset(
            song.localPath,
            tag: MediaItem(
              id: song.id,
              album: song.album,
              title: song.title,
              artist: song.artist,
              artUri: artUri,
            ),
          ),
        );
      } else {
        sources.add(
          AudioSource.file(
            song.localPath,
            tag: MediaItem(
              id: song.id,
              album: song.album,
              title: song.title,
              artist: song.artist,
              artUri: artUri,
            ),
          ),
        );
      }
    }

    _playlistSource = ConcatenatingAudioSource(children: sources);
    
    try {
      await _player.setAudioSource(_playlistSource!, initialIndex: initialIndex);
    } catch (e) {
      debugPrint("Error setting audio source: $e");
    }
  }

  // Queue manipulation
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    if (_playlistSource != null && currentIndex >= 0 && newIndex >= 0) {
      try {
        await _playlistSource!.move(currentIndex, newIndex);
        final item = _currentPlaylist.removeAt(currentIndex);
        _currentPlaylist.insert(newIndex, item);
      } catch (e) {
        debugPrint("Error moving queue item: $e");
      }
    }
  }

  Future<void> removeQueueItem(int index) async {
    if (_playlistSource != null && index >= 0 && index < _currentPlaylist.length) {
      try {
        await _playlistSource!.removeAt(index);
        _currentPlaylist.removeAt(index);
      } catch (e) {
        debugPrint("Error removing queue item: $e");
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
    await _player.seek(position, index: index);
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
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

  // Stream getter for active index
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  // Stream getter for active song
  Stream<SongModel?> get currentSongStream =>
      _player.currentIndexStream.map((index) {
        if (index == null || index < 0 || index >= _currentPlaylist.length) return null;
        return _currentPlaylist[index];
      });

  // Stream getter for playing status
  Stream<bool> get isPlayingStream => _player.playingStream;
}
