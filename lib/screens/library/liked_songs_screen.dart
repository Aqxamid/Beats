// screens/library/liked_songs_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/stats_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/db_service.dart';
import '../player/now_playing_screen.dart';
import '../../widgets/mini_player.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);

    return Scaffold(
      backgroundColor: BeatSpillTheme.background,
      appBar: AppBar(
        title: const Text('Liked Songs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: likedSongs.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No liked songs yet.',
                        style: TextStyle(color: BeatSpillTheme.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: song.artBytes != null && song.artBytes!.isNotEmpty
                                ? Image.memory(
                                    Uint8List.fromList(song.artBytes!),
                                    key: ValueKey('liked_art_${song.id}'),
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
                                          fontSize: 16,
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                song.isLiked ? Icons.favorite : Icons.favorite_border,
                                color: song.isLiked ? BeatSpillTheme.green : BeatSpillTheme.textSecondary,
                                size: 20,
                              ),
                              onPressed: () async {
                                await DbService.instance.toggleLike(song.id);
                                ref.invalidate(likedSongsProvider);
                                ref.invalidate(allSongsProvider);
                                ref.read(playerProvider.notifier).refreshCurrentSong();
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          ref.read(playerProvider.notifier).playQueue(songs, startIndex: index);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NowPlayingScreen(song: song),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading liked songs'),
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
}
