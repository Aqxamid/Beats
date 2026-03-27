// services/lyrics_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/song.dart';
import 'db_service.dart';

class LyricsService {
  LyricsService._();
  static final LyricsService instance = LyricsService._();

  static const _baseUrl = 'https://lrclib.net/api';

  /// Fetch lyrics for a song. Tries to find synced lyrics first.
  /// Result is cached in the Song model in Isar for offline use.
  Future<String?> fetchLyrics(Song song) async {
    if (song.isHidden) return null;
    // 1. Always re-read from Isar to get the latest cached lyrics
    //    (the in-memory Song object may be stale)
    final freshSong = await DbService.instance.songs.get(song.id);
    if (freshSong != null && freshSong.lyrics != null && freshSong.lyrics!.isNotEmpty) {
      // Update the in-memory object too
      song.lyrics = freshSong.lyrics;
      return freshSong.lyrics;
    }

    try {
      // 2. Search on LRCLIB
      final response = await http.get(
        Uri.parse('$_baseUrl/get?artist_name=${Uri.encodeComponent(song.artist)}&track_name=${Uri.encodeComponent(song.title)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Prefer syncedLyrics, then plainLyrics
        final lyrics = data['syncedLyrics'] ?? data['plainLyrics'];
        if (lyrics != null && lyrics is String) {
          // 3. Cache it in Isar for offline use
          song.lyrics = lyrics;
          await DbService.instance.isar.writeTxn(() async {
            await DbService.instance.songs.put(song);
          });
          return lyrics;
        }
      }
    } catch (e) {
      // Network error — try one more time to read from Isar
      // in case the song object in memory didn't have it
      final fallback = await DbService.instance.songs.get(song.id);
      if (fallback != null && fallback.lyrics != null && fallback.lyrics!.isNotEmpty) {
        return fallback.lyrics;
      }
    }
    return null;
  }

  /// Bulk download all missing lyrics.
  /// [onProgress] receives the current progress (0 to total).
  Future<void> downloadAllMissingLyrics({
    required void Function(int current, int total) onProgress,
  }) async {
    final allSongs = await DbService.instance.songs.where().filter().isHiddenEqualTo(false).findAll();
    final missing = allSongs.where((s) => s.lyrics == null || s.lyrics!.trim().isEmpty).toList();

    int completed = 0;
    final total = missing.length;
    onProgress(0, total);

    for (final song in missing) {
      await fetchLyrics(song);
      completed++;
      onProgress(completed, total);
      // Wait to avoid rate-limiting from lrclib
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
