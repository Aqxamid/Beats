// providers/stats_provider.dart
// Riverpod providers for all stats data used in StatsScreen and HomeScreen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../services/db_service.dart';
import '../services/lyrics_service.dart';
import '../services/discovery_service.dart';
import '../models/song.dart';

// ── Period state ─────────────────────────────────────────────
enum StatsPeriod { week, month, quarter, allTime }

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.month);

// Helper to calculate date range based on period
(DateTime, DateTime) _getRange(StatsPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case StatsPeriod.week:
      return (now.subtract(const Duration(days: 7)), now);
    case StatsPeriod.quarter:
      return (now.subtract(const Duration(days: 90)), now);
    case StatsPeriod.allTime:
      return (DateTime(2000), now);
    case StatsPeriod.month:
    default:
      return (DateTime(now.year, now.month, 1), now);
  }
}

// ── Minutes listened ─────────────────────────────────────────
final minutesProvider = FutureProvider<int>((ref) async {
  final period = ref.watch(statsPeriodProvider);
  final range = _getRange(period);
  return DbService.instance.minutesForRange(range.$1, range.$2);
});

// ── Song count ───────────────────────────────────────────────
final songCountProvider = FutureProvider<int>((ref) async {
  final period = ref.watch(statsPeriodProvider);
  final range = _getRange(period);
  return DbService.instance.songsForRange(range.$1, range.$2);
});

// ── Current streak ───────────────────────────────────────────
final streakProvider = FutureProvider<int>((ref) async {
  return DbService.instance.currentStreak();
});

// ── Skip rate ────────────────────────────────────────────────
final skipRateProvider = FutureProvider<double>((ref) async {
  return DbService.instance.overallSkipRate();
});

// ── Heatmap ──────────────────────────────────────────────────
final heatmapProvider = FutureProvider<List<List<int>>>((ref) async {
  final period = ref.watch(statsPeriodProvider);
  final range = _getRange(period);
  return DbService.instance.heatmapForRange(range.$1, range.$2);
});

// ── Genre breakdown ──────────────────────────────────────────
final genreBreakdownProvider = FutureProvider<Map<String, int>>((ref) async {
  final period = ref.watch(statsPeriodProvider);
  final range = _getRange(period);
  return DbService.instance.genreBreakdownForRange(range.$1, range.$2);
});

// ── Top artists ──────────────────────────────────────────────
final topArtistsProvider =
    FutureProvider<List<MapEntry<String, int>>>((ref) async {
  final period = ref.watch(statsPeriodProvider);
  final range = _getRange(period);
  return DbService.instance
      .topArtistsForRange(range.$1, range.$2, limit: 5);
});

// ── Recently played songs (for HomeScreen) ───────────────────
final recentSongsProvider = FutureProvider<List<Song>>((ref) async {
  // Get all songs that have been played, then sort by lastPlayedAt
  final songs = await DbService.instance.songs
      .filter()
      .lastPlayedAtIsNotNull()
      .findAll();
  songs.sort((a, b) => (b.lastPlayedAt ?? DateTime(0))
      .compareTo(a.lastPlayedAt ?? DateTime(0)));
  return songs.take(10).toList();
});

// ── All songs (for Library/Search) ───────────────────────────
final allSongsProvider = FutureProvider<List<Song>>((ref) async {
  return DbService.instance.songs.where().findAll();
});

// ── Liked songs ──────────────────────────────────────────────
final likedSongsProvider = FutureProvider<List<Song>>((ref) async {
  return DbService.instance.songs
      .filter()
      .isLikedEqualTo(true)
      .findAll();
});

// ── Tab navigation provider ──────────────────────────────────
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

// ── Lyrics fetching ──────────────────────────────────────────
final lyricsProvider = FutureProvider.family<String?, Song>((ref, song) async {
  // Use a separate service for lyrics
  final lyrics = await LyricsService.instance.fetchLyrics(song);
  return lyrics;
});

// ── Editor's picks ───────────────────────────────────────────
final editorPicksProvider = FutureProvider<List<Song>>((ref) async {
  return DiscoveryService.instance.getEditorPicks();
});

