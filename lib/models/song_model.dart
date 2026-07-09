import 'package:hive/hive.dart';

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final String duration;
  final String mood;
  final String localPath;
  final String coverPath;
  final bool favorite;
  final int playCount;
  final String lastPlayed;
  final String dateAdded;
  
  // Mood Detection Engine fields
  final String primaryMood;
  final String secondaryMood;
  final double confidence;
  final int analysisVersion;
  final String analyzedAt;
  final int bitrate;
  final int sampleRate;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.mood,
    required this.localPath,
    required this.coverPath,
    required this.favorite,
    required this.playCount,
    required this.lastPlayed,
    required this.dateAdded,
    String? primaryMood,
    String? secondaryMood,
    double? confidence,
    int? analysisVersion,
    String? analyzedAt,
    int? bitrate,
    int? sampleRate,
  }) : this.primaryMood = primaryMood ?? mood,
       this.secondaryMood = secondaryMood ?? 'Relax',
       this.confidence = confidence ?? 1.0,
       this.analysisVersion = analysisVersion ?? 1,
       this.analyzedAt = analyzedAt ?? '',
       this.bitrate = bitrate ?? 0,
       this.sampleRate = sampleRate ?? 0;

  // Backward compatibility getters
  String get coverArt => coverPath;
  String get assetPath => localPath;
  String get albumCover => coverPath;

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? duration,
    String? mood,
    String? localPath,
    String? coverPath,
    bool? favorite,
    int? playCount,
    String? lastPlayed,
    String? dateAdded,
    String? primaryMood,
    String? secondaryMood,
    double? confidence,
    int? analysisVersion,
    String? analyzedAt,
    int? bitrate,
    int? sampleRate,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      mood: mood ?? this.mood,
      localPath: localPath ?? this.localPath,
      coverPath: coverPath ?? this.coverPath,
      favorite: favorite ?? this.favorite,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      dateAdded: dateAdded ?? this.dateAdded,
      primaryMood: primaryMood ?? this.primaryMood,
      secondaryMood: secondaryMood ?? this.secondaryMood,
      confidence: confidence ?? this.confidence,
      analysisVersion: analysisVersion ?? this.analysisVersion,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
    );
  }

  // Convert legacy JSON map to new database model for initial seeding
  factory SongModel.fromJson(Map<String, dynamic> json) {
    final songId = json['id'] as String;
    final moodName = json['mood'] as String;
    return SongModel(
      id: songId,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String? ?? 'Offline Album',
      genre: json['genre'] as String? ?? 'Sample',
      duration: json['duration'] as String,
      mood: moodName,
      localPath: json['assetPath'] as String? ?? 'assets/music/${moodName.toLowerCase()}/$songId.mp3',
      coverPath: json['coverArt'] as String? ?? 'assets/covers/${moodName.toLowerCase()}/$songId.jpg',
      favorite: false,
      playCount: 0,
      lastPlayed: '',
      dateAdded: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'mood': mood,
      'localPath': localPath,
      'coverPath': coverPath,
      'favorite': favorite,
      'playCount': playCount,
      'lastPlayed': lastPlayed,
      'dateAdded': dateAdded,
      'primaryMood': primaryMood,
      'secondaryMood': secondaryMood,
      'confidence': confidence,
      'analysisVersion': analysisVersion,
      'analyzedAt': analyzedAt,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
    };
  }
}

class SongModelAdapter extends TypeAdapter<SongModel> {
  @override
  final int typeId = 0;

  @override
  SongModel read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final artist = reader.readString();
    final album = reader.readString();
    final genre = reader.readString();
    final duration = reader.readString();
    final mood = reader.readString();
    final localPath = reader.readString();
    final coverPath = reader.readString();
    final favorite = reader.readBool();
    final playCount = reader.readInt();
    final lastPlayed = reader.readString();
    final dateAdded = reader.readString();

    // Default values for evolutionary fields
    String primaryMood = mood;
    String secondaryMood = 'Relax';
    double confidence = 1.0;
    int analysisVersion = 1;
    String analyzedAt = '';
    int bitrate = 0;
    int sampleRate = 0;

    try {
      primaryMood = reader.readString();
      secondaryMood = reader.readString();
      confidence = reader.readDouble();
      analysisVersion = reader.readInt();
      analyzedAt = reader.readString();
      bitrate = reader.readInt();
      sampleRate = reader.readInt();
    } catch (_) {}

    return SongModel(
      id: id,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      duration: duration,
      mood: mood,
      localPath: localPath,
      coverPath: coverPath,
      favorite: favorite,
      playCount: playCount,
      lastPlayed: lastPlayed,
      dateAdded: dateAdded,
      primaryMood: primaryMood,
      secondaryMood: secondaryMood,
      confidence: confidence,
      analysisVersion: analysisVersion,
      analyzedAt: analyzedAt,
      bitrate: bitrate,
      sampleRate: sampleRate,
    );
  }

  @override
  void write(BinaryWriter writer, SongModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.artist);
    writer.writeString(obj.album);
    writer.writeString(obj.genre);
    writer.writeString(obj.duration);
    writer.writeString(obj.mood);
    writer.writeString(obj.localPath);
    writer.writeString(obj.coverPath);
    writer.writeBool(obj.favorite);
    writer.writeInt(obj.playCount);
    writer.writeString(obj.lastPlayed);
    writer.writeString(obj.dateAdded);
    writer.writeString(obj.primaryMood);
    writer.writeString(obj.secondaryMood);
    writer.writeDouble(obj.confidence);
    writer.writeInt(obj.analysisVersion);
    writer.writeString(obj.analyzedAt);
    writer.writeInt(obj.bitrate);
    writer.writeInt(obj.sampleRate);
  }
}
