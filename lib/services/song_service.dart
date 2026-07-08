import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/song_model.dart';

class SongService {
  // Load local JSON from assets and parse it into a list of SongModels
  Future<List<SongModel>> loadSongs() async {
    try {
      final String response = await rootBundle.loadString('assets/data/songs.json');
      final List<dynamic> data = json.decode(response) as List<dynamic>;
      return data.map((jsonItem) => SongModel.fromJson(jsonItem as Map<String, dynamic>)).toList();
    } catch (e) {
      // Return empty list or fallback songs if loading fails (should not fail under normal execution)
      return [];
    }
  }
}
