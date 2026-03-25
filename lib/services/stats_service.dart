// services/stats_service.dart
// Computes all stats needed for Wrapped from PlayEvent records.
// Called once when user triggers Wrapped generation.
import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/wrapped_report.dart';
import '../models/play_event.dart';
import 'db_service.dart';

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  final _db = DbService.instance;

  /// Build a WrappedReport for a given year+month (monthly cadence).
  /// Returns a partially-filled report ready for LLM recap generation.
  Future<WrappedReport> buildMonthlyReport(int year, int month) async {
    final report = WrappedReport()
      ..cadence = 'monthly'
      ..generatedAt = DateTime.now()
      ..periodLabel = _monthLabel(year, month);

    // ── Core stats ─────────────────────────────────
    report.totalMinutes = await _db.minutesForMonth(year, month);
    report.totalSongs   = await _db.songsForMonth(year, month);
    report.streakDays   = await _db.currentStreak();
    report.skipRate     = await _db.overallSkipRate();

    // ── Top artist ──────────────────────────────────
    final topArtists = await _db.topArtistsForMonth(year, month, limit: 1);
    if (topArtists.isNotEmpty) {
      report.topArtist      = topArtists.first.key;
      report.topArtistPlays = topArtists.first.value;
    } else {
      report.topArtist      = 'Unknown';
      report.topArtistPlays = 0;
    }

    // ── Top song ────────────────────────────────────
    final allSongs = await _db.songs.where().findAll();
    if (allSongs.isNotEmpty) {
      allSongs.sort((a, b) => b.playCount.compareTo(a.playCount));
      report.topSong = allSongs.first.title;
    } else {
      report.topSong = 'Unknown';
    }

    // ── Heatmap → peak hour ─────────────────────────
    final heatmap = await _db.heatmapForMonth(year, month);
    int peakHour = 0;
    int peakCount = 0;
    for (int h = 0; h < 24; h++) {
      final total = heatmap.fold<int>(0, (sum, row) => sum + (h < row.length ? row[h] : 0));
      if (total > peakCount) {
        peakCount = total;
        peakHour  = h;
      }
    }
    report.peakHourLabel = _hourLabel(peakHour);

    // ── Personality type ────────────────────────────
    final personality = _derivePersonality(peakHour, report.skipRate);
    report.personalityType  = personality.$1;
    report.personalityEmoji = personality.$2;

    // ── Genre breakdown ─────────────────────────────
    final genres = await _db.genreBreakdownForMonth(year, month);
    report.genreJsonStr = jsonEncode(genres);

    return report;
  }

  // ── Helpers ─────────────────────────────────────────────────

  String _monthLabel(int year, int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month]} $year';
  }

  String _hourLabel(int hour) {
    if (hour == 0)  return '12am';
    if (hour < 12)  return '${hour}am';
    if (hour == 12) return '12pm';
    return '${hour - 12}pm';
  }

  /// Derive personality type from listening habits
  (String, String) _derivePersonality(int peakHour, double skipRate) {
    if (peakHour >= 22 || peakHour <= 2) return ('Night Owl',    '🦉');
    if (peakHour >= 5  && peakHour <= 8) return ('Early Bird',   '🐦');
    if (skipRate > 0.4)                  return ('The Skimmer',  '⏩');
    if (peakHour >= 12 && peakHour <= 14) return ('Lunch Listener', '🎧');
    return ('The All-Day Streamer', '🎵');
  }
}
