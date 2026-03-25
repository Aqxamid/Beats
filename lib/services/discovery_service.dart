// services/discovery_service.dart
import 'dart:math';
import 'package:isar/isar.dart';
import '../models/song.dart';
import 'db_service.dart';

class DiscoveryService {
  DiscoveryService._();
  static final DiscoveryService instance = DiscoveryService._();

  final _db = DbService.instance;

  /// Get 10 "Editor's Picks" using various heuristic algorithms.
  Future<List<Song>> getEditorPicks() async {
    final allSongs = await _db.songs.where().findAll();
    if (allSongs.length < 10) return allSongs;

    final picks = <Song>[];
    final random = Random();

    // 1. "Forgotten Favorites" (High play count, not played in > 7 days)
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final forgotten = allSongs.where((s) => 
      s.playCount > 5 && 
      (s.lastPlayedAt == null || s.lastPlayedAt!.isBefore(weekAgo))
    ).toList();
    forgotten.shuffle();
    picks.addAll(forgotten.take(3));

    // 2. "Genre Spotlight" (Randomly pick 3 from a top genre)
    final counts = <String, int>{};
    for (var s in allSongs) counts[s.genre] = (counts[s.genre] ?? 0) + 1;
    if (counts.isNotEmpty) {
      final topGenre = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final spotlight = allSongs.where((s) => s.genre == topGenre.first.key).toList();
      spotlight.shuffle();
      picks.addAll(spotlight.where((s) => !picks.contains(s)).take(3));
    }

    // 3. "Deep Cuts" (Long songs with low play count)
    final deepCuts = allSongs.where((s) => 
      s.durationMs > 300000 && s.playCount < 3
    ).toList();
    deepCuts.shuffle();
    picks.addAll(deepCuts.where((s) => !picks.contains(s)).take(2));

    // 4. Fill the rest randomly
    while (picks.length < 10) {
      final s = allSongs[random.nextInt(allSongs.length)];
      if (!picks.contains(s)) picks.add(s);
    }

    return picks.take(10).toList();
  }
}
