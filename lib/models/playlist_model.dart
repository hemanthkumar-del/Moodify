import 'package:hive/hive.dart';

class PlaylistModel {
  final String id;
  final String name;
  final List<String> songIds;
  final String emoji;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.songIds,
    this.emoji = '🎵',
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    String? emoji,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      emoji: emoji ?? this.emoji,
    );
  }
}

class PlaylistModelAdapter extends TypeAdapter<PlaylistModel> {
  @override
  final int typeId = 1;

  @override
  PlaylistModel read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final songIds = reader.readStringList();
    
    // Support database schema evolution for existing custom playlists
    String emoji = '🎵';
    try {
      emoji = reader.readString();
    } catch (_) {}

    return PlaylistModel(
      id: id,
      name: name,
      songIds: songIds,
      emoji: emoji,
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeStringList(obj.songIds);
    writer.writeString(obj.emoji);
  }
}
