// services/stats_service.dart
// Computes all stats needed for Wrapped from PlayEvent records.
// Called once when user triggers Wrapped generation.
import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/wrapped_report.dart';
import '../models/play_event.dart';
import 'db_service.dart';
import 'llm_service.dart';

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  final _db = DbService.instance;

  /// Build a RecapReport for a given year+month (monthly cadence).
  Future<WrappedReport> buildMonthlyReport(int year, int month) async {
    final report = WrappedReport()
      ..cadence = 'monthly'
      ..generatedAt = DateTime.now()
      ..periodLabel = _monthLabel(year, month);

    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);

    return _fillReportForRange(report, start, end);
  }

  /// Build an Annual RecapReport for a given year.
  Future<WrappedReport> buildYearlyReport(int year) async {
    final report = WrappedReport()
      ..cadence = 'yearly'
      ..generatedAt = DateTime.now()
      ..periodLabel = '$year Recap';

    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    return _fillReportForRange(report, start, end);
  }

  Future<WrappedReport> _fillReportForRange(WrappedReport report, DateTime start, DateTime end) async {
    // ── Core stats ─────────────────────────────────
    report.totalMinutes = await _db.minutesForRange(start, end);
    report.totalSongs   = await _db.songsForRange(start, end);
    report.streakDays   = await _db.currentStreak();
    report.skipRate     = await _db.overallSkipRate();
    final heatmap       = await _db.heatmapForRange(start, end);

    if (report.totalMinutes == 0 && report.totalSongs == 0) {
       report.topArtist = 'None';
       report.topSong = 'None';
       report.peakHourLabel = '12am';
       report.personalityType = 'The Observer';
       report.personalityEmoji = 'music_note';
       report.genreJsonStr = '{}';
       report.slidesJsonStr = jsonEncode({'topSongs': [], 'heatmap': []});
       return report;
    }

    // ── Top artist ──────────────────────────────────
    final topArtists = await _db.topArtistsForRange(start, end, limit: 1);
    if (topArtists.isNotEmpty) {
      report.topArtist      = topArtists.first.key;
      report.topArtistPlays = topArtists.first.value;
    } else {
      report.topArtist      = 'Unknown';
      report.topArtistPlays = 0;
    }

    // ── Top songs (Monthly accurate) ────────────────
    final top5JSON = <Map<String, dynamic>>[];
    final topSongsWithCounts = await _db.topSongsForRange(start, end, limit: 5);
    if (topSongsWithCounts.isNotEmpty) {
      report.topSong = topSongsWithCounts.first.key.title;

      // Extract accurate minutes from PlayEvents for these specific songs
      for (final entry in topSongsWithCounts) {
        final song = entry.key;
        final count = entry.value;

        // Sum actual listened minutes for THIS song in THIS range
        final songEvents = await _db.playEvents
            .filter()
            .songTitleEqualTo(song.title)
            .and()
            .artistEqualTo(song.artist)
            .and()
            .startedAtBetween(start, end)
            .findAll();
        
        final songMs = songEvents.fold<int>(0, (sum, e) => sum + e.listenedMs);
        final songMins = songMs ~/ 60000;

        top5JSON.add({
          'id': song.id,
          'title': song.title,
          'artist': song.artist,
          'playCount': count,
          'minutes': songMins
        });
      }
      report.slidesJsonStr = jsonEncode({
        'topSongs': top5JSON,
        'heatmap': heatmap,
      });
    } else {
      report.topSong = 'Unknown';
      report.slidesJsonStr = jsonEncode({'topSongs': [], 'heatmap': heatmap});
    }

    // ── Genre breakdown ─────────────────────────────
    final genres = await _db.genreBreakdownForRange(start, end);
    report.genreJsonStr = jsonEncode(genres);

    // ── Peak hour ──────────────────────────────────
    int peakHour = 0;
    int peakCount = 0;
    for (int h = 0; h < 24; h++) {
      int total = 0;
      for (var row in heatmap) {
        if (h < (row as List).length) total += (row[h] as num).toInt();
      }
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

    // ── AI Insights (Personality, Song, Artist, Minutes, Time) ──
    String personalityTitle = report.personalityType; // Fallback
    String songInsight = "Your soul on repeat."; // Fallback
    String artistInsight = "They were there for you. All ${report.topArtistPlays} times.";
    String minutesInsight = "That's many hours. We're not judging.";
    String timeInsight = "${report.peakHourLabel} - The perfect hour.";
    
    try {
      final llm = LlmService.instance;
      // Parallelize to save time
      final futures = await Future.wait([
        llm.generateListeningPersonality(report),
        llm.generateSongInsight(report.topSong),
        llm.generateArtistInsight(report.topArtist, report.topArtistPlays),
        llm.generateMinutesInsight(report.totalMinutes),
        llm.generateTimeInsight(peakHour, report.totalMinutes),
      ]);
      
      personalityTitle = futures[0];
      songInsight = futures[1];
      artistInsight = futures[2];
      minutesInsight = futures[3];
      timeInsight = futures[4];
    } catch (_) {}

    // ── Build slides JSON ──
    // Note: We're embedding insights here to avoid Isar schema changes in production.
    report.slidesJsonStr = jsonEncode({
      'topSongs': top5JSON,
      'heatmap': heatmap,
      'insights': {
        'personalityTitle': personalityTitle,
        'songInsight': songInsight,
        'artistInsight': artistInsight,
        'minutesInsight': minutesInsight,
        'timeInsight': timeInsight,
      }
    });

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
  /// Returns (type name, icon name) — icon name maps to Material icon in UI
  (String, String) _derivePersonality(int peakHour, double skipRate) {
    if (skipRate > 0.5)                   return ('The Skimmer',  'fast_forward');
    if (skipRate < 0.05)                  return ('The Loyalist', 'favorite');
    
    if (peakHour >= 22 || peakHour <= 3)  return ('The Night Owl', 'nightlife');
    if (peakHour >= 5  && peakHour <= 8)  return ('The Early Bird', 'wb_twilight');
    if (peakHour >= 12 && peakHour <= 14) return ('The Lunchtime Legend', 'restaurant');
    if (peakHour >= 17 && peakHour <= 19) return ('The Commuter', 'directions_subway');
    if (peakHour >= 20 && peakHour <= 21) return ('The Evening Enthusiast', 'bedtime');
    
    if (skipRate < 0.15)                  return ('The Deep Diver', 'waves');
    if (skipRate > 0.3)                   return ('The Genre Hopper', 'shuffle');
    
    return ('The Musical Explorer', 'explore');
  }
}
