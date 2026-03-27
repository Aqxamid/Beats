// ─────────────────────────────────────────────────────────────
// models/song.dart
// Represents a local audio file scanned from the device.
// ─────────────────────────────────────────────────────────────
import 'package:isar/isar.dart';

part 'song.g.dart';

@Collection()
class Song {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String filePath;

  String? uri;

  late String title;
  late String artist;
  late String album;
  late String genre; // e.g. "Pop", "Indie"

  int durationMs = 0;
  int playCount = 0;
  int skipCount = 0;
  bool isLiked = false;
  bool isHidden = false;

  /// Album art bytes stored inline for offline use (nullable)
  List<byte>? artBytes;

  DateTime? lastPlayedAt;
  
  /// Cached lyrics (JSON or plain text)
  String? lyrics;

  // Skip rate: skipCount / max(playCount, 1)
  double get skipRate => playCount == 0 ? 0 : skipCount / playCount;
}
