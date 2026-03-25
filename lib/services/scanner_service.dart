// services/scanner_service.dart
// Scans device for audio files using on_audio_query and saves to Isar.
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';
import 'db_service.dart';

class ScannerService {
  ScannerService._();
  static final ScannerService instance = ScannerService._();

  final OnAudioQuery _audioQuery = OnAudioQuery();
  final _db = DbService.instance;

  /// Request storage/audio permission. Returns true if granted.
  Future<bool> requestPermission() async {
    // Android 13+ uses READ_MEDIA_AUDIO; older uses READ_EXTERNAL_STORAGE
    PermissionStatus status = await Permission.audio.request();
    if (status.isGranted) return true;

    // Fallback for older Android versions
    status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Scan all audio files on device and save new ones to Isar.
  /// [onProgress] receives (current, total) for progress display.
  /// Returns count of new songs added.
  Future<int> scanAndSave({
    void Function(int current, int total)? onProgress,
  }) async {
    final deviceSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    int added = 0;
    final total = deviceSongs.length;

    for (int i = 0; i < deviceSongs.length; i++) {
      final info = deviceSongs[i];
      onProgress?.call(i + 1, total);

      // Skip files shorter than 30 seconds (likely ringtones/notifications)
      if ((info.duration ?? 0) < 30000) continue;

      final filePath = info.data;

      // Check if already in Isar
      final existing = await _db.songs.filter().filePathEqualTo(filePath).findFirst();
      if (existing != null) continue;

      // Query artwork
      List<int>? artBytes;
      try {
        artBytes = await _audioQuery.queryArtwork(
          info.id,
          ArtworkType.AUDIO,
          quality: 200,
          size: 400,
        );
      } catch (_) {
        // Artwork not available — that's fine
      }

      final song = Song()
        ..filePath = filePath
        ..title = info.title
        ..artist = info.artist ?? 'Unknown Artist'
        ..album = info.album ?? 'Unknown Album'
        ..genre = info.genre ?? 'Unknown'
        ..durationMs = info.duration ?? 0
        ..artBytes = (artBytes != null && artBytes.isNotEmpty) ? artBytes : null;

      await _db.isar.writeTxn(() async {
        await _db.songs.put(song);
      });
      added++;
    }

    // --- Pruning step: remove songs that no longer exist on disk ---
    final allSavedSongs = await _db.songs.where().findAll();
    final toDelete = <int>[];
    for (final s in allSavedSongs) {
      if (!File(s.filePath).existsSync()) {
        toDelete.add(s.id);
      }
    }
    if (toDelete.isNotEmpty) {
      await _db.isar.writeTxn(() async {
        await _db.songs.deleteAll(toDelete);
      });
    }

    return added;
  }

  /// Get count of songs already in Isar
  Future<int> savedSongCount() async {
    return _db.songs.count();
  }
}
