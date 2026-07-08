import 'package:hive/hive.dart';

class PlaylistModel {
  final String id;
  final String name;
  final List<String> songIds;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.songIds,
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    List<String>? songIds,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }
}

class PlaylistModelAdapter extends TypeAdapter<PlaylistModel> {
  @override
  final int typeId = 1;

  @override
  PlaylistModel read(BinaryReader reader) {
    return PlaylistModel(
      id: reader.readString(),
      name: reader.readString(),
      songIds: reader.readStringList(),
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeStringList(obj.songIds);
  }
}
