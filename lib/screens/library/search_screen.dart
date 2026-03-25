// screens/library/search_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mini_player.dart';
import '../../providers/stats_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/song.dart';
import '../player/now_playing_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSongs = ref.watch(allSongsProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            children: [
              const SizedBox(height: 16),
                  Text('Search',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 20)),
                  const SizedBox(height: 12),

                  // ── Search bar ────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.black, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Artists, songs, or albums',
                              hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close,
                                color: Colors.black54, size: 16),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Genre grid (when not searching) ──
                  if (_query.isEmpty) ...[
                    Text('Browse categories',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: allSongs.when(
                        data: (songs) => [
                          _GenreCard('Pop', const Color(0xFF1DB954), songs.firstWhere((s) => s.genre == 'Pop', orElse: () => songs.first)),
                          _GenreCard('Indie', const Color(0xFF8E44AD), songs.firstWhere((s) => s.genre == 'Indie', orElse: () => songs.first)),
                          _GenreCard('K-Pop', const Color(0xFFE74C3C), songs.firstWhere((s) => s.genre == 'K-Pop', orElse: () => songs.first)),
                          _GenreCard('R&B', const Color(0xFFE8821A), songs.firstWhere((s) => s.genre == 'R&B', orElse: () => songs.first)),
                          _GenreCard('Hip-Hop', const Color(0xFF2C3E50), songs.firstWhere((s) => s.genre == 'Hip-Hop', orElse: () => songs.first)),
                          _GenreCard('Rock', const Color(0xFF1A3A5C), songs.firstWhere((s) => s.genre == 'Rock', orElse: () => songs.first)),
                          _GenreCard('Jazz', const Color(0xFF2D6A4F), songs.firstWhere((s) => s.genre == 'Jazz', orElse: () => songs.first)),
                          _GenreCard('Classical', const Color(0xFF5C4A1E), songs.firstWhere((s) => s.genre == 'Classical', orElse: () => songs.first)),
                        ],
                        loading: () => List.generate(8, (_) => Container(color: BeatSpillTheme.surfaceAlt)),
                        error: (_, __) => [const Text('Error')],
                      ),
                    ),
                  ],

                  // ── Search results ────────────────────
                  if (_query.isNotEmpty)
                    allSongs.when(
                      data: (songs) {
                        final q = _query.toLowerCase();
                        final results = songs.where((s) =>
                            s.title.toLowerCase().contains(q) ||
                            s.artist.toLowerCase().contains(q) ||
                            s.album.toLowerCase().contains(q)).toList();
                        return _SearchResults(
                          query: _query,
                          results: results,
                          onTap: (song, index) {
                            ref
                                .read(playerProvider.notifier)
                                .playQueue(results, startIndex: index);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NowPlayingScreen(song: song),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error loading songs'),
                    ),

                  const SizedBox(height: 100), // Space to scroll past miniplayer
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        );
  }
}

class _GenreCard extends StatelessWidget {
  final String name;
  final Color color;
  final Song? song;
  const _GenreCard(this.name, this.color, [this.song]);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name category results coming soon')),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
          image: song?.artBytes != null && song!.artBytes!.isNotEmpty
              ? DecorationImage(
                  image: MemoryImage(Uint8List.fromList(song!.artBytes!)),
                  fit: BoxFit.cover,
                  opacity: 0.35,
                )
              : null,
        ),
        alignment: Alignment.centerLeft,
        child: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final String query;
  final List<Song> results;
  final void Function(Song song, int index) onTap;
  const _SearchResults({
    required this.query,
    required this.results,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Results for "$query"',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (results.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No local songs found',
                  style: TextStyle(color: BeatSpillTheme.textMuted)),
            ),
          )
        else
          ...results.asMap().entries.map((entry) {
            final song = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: song.artBytes != null && song.artBytes!.isNotEmpty
                      ? Image.memory(
                          Uint8List.fromList(song.artBytes!),
                          key: ValueKey('search_art_${song.id}'),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Container(
                          color: const Color(0xFFC0392B),
                          child: Center(
                            child: Text(
                              song.title.isNotEmpty ? song.title[0] : '♪',
                              style: const TextStyle(
                                color: Color(0xFFF1C40F),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              title: Text(song.title,
                  style: const TextStyle(
                      color: BeatSpillTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist,
                  style: const TextStyle(
                      color: BeatSpillTheme.textSecondary, fontSize: 11)),
              onTap: () => onTap(song, entry.key),
            );
          }),
      ],
    );
  }
}
