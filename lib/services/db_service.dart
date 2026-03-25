// ─────────────────────────────────────────────────────────────
// services/db_service.dart
// Singleton that opens Isar and exposes typed collection helpers.
// ─────────────────────────────────────────────────────────────
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';
import '../models/play_event.dart';
import '../models/wrapped_report.dart';
import '../models/playlist.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  late Isar _isar;
  Isar get isar => _isar;

  Future<void> open() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [SongSchema, PlayEventSchema, WrappedReportSchema, PlaylistSchema],
      directory: dir.path,
    );
  }

  Future<void> toggleLike(int songId) async {
    await _isar.writeTxn(() async {
      final song = await songs.get(songId);
      if (song != null) {
        song.isLiked = !song.isLiked;
        await songs.put(song);
      }
    });
  }

  // ── Shortcuts ──────────────────────────────────────
  IsarCollection<Song>          get songs          => _isar.songs;
  IsarCollection<PlayEvent>     get playEvents     => _isar.playEvents;
  IsarCollection<WrappedReport> get wrappedReports => _isar.wrappedReports;
  IsarCollection<Playlist>      get playlists      => _isar.playlists;

  // ── Stats helpers ──────────────────────────────────

  // ── Stats queries (refactored for range support) ──────

  Future<int> minutesForRange(DateTime start, DateTime end) async {
    final events = await playEvents
        .filter()
        .startedAtBetween(start, end)
        .findAll();
    final totalMs = events.fold<int>(0, (sum, e) => sum + e.listenedMs);
    return totalMs ~/ 60000;
  }

  Future<int> songsForRange(DateTime start, DateTime end) async {
    final events = await playEvents
        .filter()
        .startedAtBetween(start, end)
        .findAll();
    return events.map((e) => e.songTitle).toSet().length;
  }

  /// Listening streak: consecutive days with ≥1 play up to today
  Future<int> currentStreak() async {
    final all = await playEvents
        .where()
        .findAll();
    all.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (all.isEmpty) return 0;

    final days = all.map((e) {
      final d = e.startedAt;
      return DateTime(d.year, d.month, d.day);
    }).toSet().toList()..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Overall skip rate (all time)
  Future<double> overallSkipRate() async {
    final total = await playEvents.count();
    if (total == 0) return 0;
    final skipped = await playEvents.filter().wasSkippedEqualTo(true).count();
    return skipped / total;
  }

  /// Heatmap: returns a 7×24 matrix [dayOfWeek][hour] = count
  /// dayOfWeek: 0=Mon … 6=Sun
  Future<List<List<int>>> heatmapForRange(DateTime start, DateTime end) async {
    final events = await playEvents
        .filter()
        .startedAtBetween(start, end)
        .findAll();

    final matrix = List.generate(7, (_) => List.filled(24, 0));
    for (final e in events) {
      final dow = (e.dayOfWeek - 1).clamp(0, 6); // Mon=0
      matrix[dow][e.hourOfDay]++;
    }
    return matrix;
  }

  Future<Map<String, int>> genreBreakdownForRange(
      DateTime start, DateTime end) async {
    final events = await playEvents
        .filter()
        .startedAtBetween(start, end)
        .findAll();

    final counts = <String, int>{};
    for (final e in events) {
      counts[e.genre] = (counts[e.genre] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<MapEntry<String, int>>> topArtistsForRange(
      DateTime start, DateTime end,
      {int limit = 5}) async {
    final events = await playEvents
        .filter()
        .startedAtBetween(start, end)
        .findAll();

    final counts = <String, int>{};
    for (final e in events) {
      counts[e.artist] = (counts[e.artist] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  // Legacy wrappers for backward compatibility
  Future<int> minutesForMonth(int year, int month) =>
      minutesForRange(DateTime(year, month), DateTime(year, month + 1));
  Future<int> songsForMonth(int year, int month) =>
      songsForRange(DateTime(year, month), DateTime(year, month + 1));
  Future<List<List<int>>> heatmapForMonth(int year, int month) =>
      heatmapForRange(DateTime(year, month), DateTime(year, month + 1));
  Future<Map<String, int>> genreBreakdownForMonth(int year, int month) =>
      genreBreakdownForRange(DateTime(year, month), DateTime(year, month + 1));
  Future<List<MapEntry<String, int>>> topArtistsForMonth(int year, int month,
          {int limit = 5}) =>
      topArtistsForRange(DateTime(year, month), DateTime(year, month + 1), limit: limit);

  // ── Song interactions ────────────────────────────

  Future<void> hideSong(Id songId) async {
    await _isar.writeTxn(() async {
      final song = await songs.get(songId);
      if (song != null) {
        song.isHidden = true;
        await songs.put(song);
      }
    });
  }

  Future<void> unhideSong(Id songId) async {
    await _isar.writeTxn(() async {
      final song = await songs.get(songId);
      if (song != null) {
        song.isHidden = false;
        await songs.put(song);
      }
    });
  }


  Future<void> updateSong(Song song) async {
    await _isar.writeTxn(() async {
      await songs.put(song);
    });
  }

  // ── Playlist management ──────────────────────────

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist()
      ..name = name
      ..createdAt = DateTime.now()
      ..coverColor = _randomColorHex();

    await _isar.writeTxn(() async {
      await playlists.put(playlist);
    });
  }

  Future<void> deletePlaylist(Id id) async {
    await _isar.writeTxn(() async {
      await playlists.delete(id);
    });
  }


  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    await _isar.writeTxn(() async {
      final p = await playlists.get(playlistId);
      final s = await songs.get(songId);
      if (p != null && s != null) {
        p.songs.add(s);
        await p.songs.save();
        p.updatedAt = DateTime.now();
        await playlists.put(p);
      }
    });
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _isar.writeTxn(() async {
      final p = await playlists.get(playlistId);
      final s = await songs.get(songId);
      if (p != null && s != null) {
        p.songs.remove(s);
        await p.songs.save();
        p.updatedAt = DateTime.now();
        await playlists.put(p);
      }
    });
  }

  String _randomColorHex() {
    const colors = ['#1DB954', '#8E44AD', '#E74C3C', '#E8821A', '#2C3E50', '#1A3A5C', '#2D6A4F', '#5C4A1E'];
    return colors[DateTime.now().millisecond % colors.length];
  }
}
