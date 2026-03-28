// models/bop_period_data.dart
// Isar model that stores one period's worth of AI-generated content.
// A "period" is a month key like "2025-03".
// Generated once per period, reused until the period rolls over.
// Stores: AI playlists (as song ID lists), Bop Recap text, personality,
// insights, and metadata about how/when it was generated.
import 'package:isar/isar.dart';

part 'bop_period_data.g.dart';

@collection
class BopPeriodData {
  Id id = Isar.autoIncrement;

  /// e.g. "2025-03" for monthly, "2025-Q1" for quarterly, "2025" for yearly
  @Index(unique: true)
  late String periodKey;

  /// "monthly" | "quarterly" | "half" | "yearly"
  late String periodType;

  /// Human-readable label shown in UI e.g. "March 2025"
  late String periodLabel;

  /// When this data was generated
  late DateTime generatedAt;

  /// Whether the LLM (local or Gemini) was used — false = template fallback
  late bool isAiGenerated;

  /// Which engine generated this: "local" | "gemini" | "template"
  late String generationEngine;

  // ── Bop Recap ──────────────────────────────────────────────────────────────
  late String recap;
  late String personalityTitle;
  late String minutesInsight;
  late String artistInsight;
  late String songInsight;
  late String timeInsight;

  // ── AI Playlists ───────────────────────────────────────────────────────────
  // Stored as JSON string: List<BopPlaylistEntry>
  // We use a String because Isar doesn't support nested collections directly.
  late String playlistsJson;

  // ── Refresh tracking ───────────────────────────────────────────────────────
  /// Song count at generation time — used to detect 20+ new songs threshold
  late int songCountAtGeneration;

  /// Number of times this period's data has been refreshed mid-period
  late int refreshCount;

  // ── Cold start flag ────────────────────────────────────────────────────────
  /// True if generated during cold start (no listening activity yet)
  late bool isColdStart;

  /// Genre preferences chosen during cold start onboarding
  late String coldStartGenres; // JSON list of genre strings
}

/// Lightweight playlist entry stored inside BopPeriodData.playlistsJson
class BopPlaylistEntry {
  final String name;
  final List<int> songIds; // Isar Song IDs
  final bool isAiGenerated;
  final String vibeTag; // e.g. "chill", "energetic" — empty for algo playlists
  final String colorHex; // for playlist cover accent

  BopPlaylistEntry({
    required this.name,
    required this.songIds,
    required this.isAiGenerated,
    this.vibeTag = '',
    this.colorHex = '#1DB954',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'songIds': songIds,
        'isAiGenerated': isAiGenerated,
        'vibeTag': vibeTag,
        'colorHex': colorHex,
      };

  factory BopPlaylistEntry.fromJson(Map<String, dynamic> j) => BopPlaylistEntry(
        name: j['name'] as String,
        songIds: List<int>.from(j['songIds'] as List),
        isAiGenerated: j['isAiGenerated'] as bool,
        vibeTag: j['vibeTag'] as String? ?? '',
        colorHex: j['colorHex'] as String? ?? '#1DB954',
      );
}