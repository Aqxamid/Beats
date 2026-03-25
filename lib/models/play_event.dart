// ─────────────────────────────────────────────────────────────
// models/play_event.dart
// Every time a song starts playing we log a PlayEvent.
// This powers the heatmap, genre breakdown, streak, and Wrapped.
// ─────────────────────────────────────────────────────────────
import 'package:isar/isar.dart';
import 'song.dart';

part 'play_event.g.dart';

@Collection()
class PlayEvent {
  Id id = Isar.autoIncrement;

  /// Link back to the song
  final song = IsarLink<Song>();

  late String songTitle;
  late String artist;
  late String genre;

  late DateTime startedAt;

  /// How many ms the user actually listened (filled in on pause/skip/stop)
  int listenedMs = 0;

  /// True if user explicitly skipped before 50% of track
  bool wasSkipped = false;

  /// Convenience getters for heatmap bucketing
  int get hourOfDay => startedAt.hour;          // 0–23
  int get dayOfWeek => startedAt.weekday;       // 1=Mon … 7=Sun
  int get month     => startedAt.month;
  int get year      => startedAt.year;
}
