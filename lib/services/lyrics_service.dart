// services/lyrics_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import 'db_service.dart';

class LyricsService {
  LyricsService._();
  static final LyricsService instance = LyricsService._();

  static const _baseUrl = 'https://lrclib.net/api';

  /// Fetch lyrics for a song. Tries to find synced lyrics first.
  /// Result is cached in the Song model in Isar.
  Future<String?> fetchLyrics(Song song) async {
    // 1. Check cache
    if (song.lyrics != null && song.lyrics!.isNotEmpty) {
      return song.lyrics;
    }

    try {
      // 2. Search on LRCLIB
      final query = Uri.encodeComponent('${song.title} ${song.artist}');
      final response = await http.get(
        Uri.parse('$_baseUrl/get?artist_name=${Uri.encodeComponent(song.artist)}&track_name=${Uri.encodeComponent(song.title)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Prefer syncedLyrics, then plainLyrics
        final lyrics = data['syncedLyrics'] ?? data['plainLyrics'];
        if (lyrics != null && lyrics is String) {
          // 3. Cache it
          song.lyrics = lyrics;
          await DbService.instance.isar.writeTxn(() async {
            await DbService.instance.songs.put(song);
          });
          return lyrics;
        }
      }
    } catch (e) {
      // Network error or no lyrics found
    }
    return null;
  }
}
