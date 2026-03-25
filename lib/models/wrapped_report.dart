// ─────────────────────────────────────────────────────────────
// models/wrapped_report.dart
// Saved after each Wrapped generation so we can show history.
// ─────────────────────────────────────────────────────────────
import 'package:isar/isar.dart';

part 'wrapped_report.g.dart';

@Collection()
class WrappedReport {
  Id id = Isar.autoIncrement;

  late String periodLabel;   // e.g. "March 2025"
  late String cadence;       // "monthly" | "quarterly" | "half-year" | "yearly"

  late DateTime generatedAt;

  // Aggregated stats
  int totalMinutes      = 0;
  int totalSongs        = 0;
  int streakDays        = 0;
  double skipRate       = 0;
  late String topArtist;
  int topArtistPlays    = 0;
  late String topSong;
  late String peakHourLabel;       // e.g. "11pm"
  late String personalityType;     // e.g. "Night Owl"
  late String personalityEmoji;    // e.g. "🦉"

  // Genre breakdown — stored as JSON string: {"Pop":38,"Indie":27}
  late String genreJsonStr;

  // LLM-generated recap paragraph
  String llmRecap = '';

  // Slide cards serialized as JSON for replay
  String slidesJsonStr = '';
}
