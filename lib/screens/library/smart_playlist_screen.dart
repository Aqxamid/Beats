// screens/library/smart_playlist_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/song.dart';
import '../../services/llm_service.dart';
import '../../providers/player_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/animated_equalizer.dart';
import '../../widgets/playlist_collage.dart';

class SmartPlaylistScreen extends ConsumerWidget {
  final SmartPlaylistData playlist;

  const SmartPlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final songs = playlist.songs;
    
    // Check if this playlist is currently playing
    final isPlaylistPlaying = songs.any((s) => s.id == playerState.currentSong?.id) && playerState.isPlaying;

    return Scaffold(
      backgroundColor: BopTheme.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [BopTheme.green, BopTheme.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          // Dynamically show 2x2 collage instead of brain/psychology icon
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: BopTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (playlist.isAiGenerated ? BopTheme.green : Colors.blueGrey).withOpacity(0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: PlaylistCollage(
                              songs: songs,
                              size: 180,
                              borderRadius: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            playlist.name,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            playlist.isAiGenerated ? 'AI-Curated Playlist' : 'Smart Playlist',
                            style: const TextStyle(color: BopTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${songs.length} songs',
                            style: const TextStyle(color: BopTheme.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          // Play Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(26),
                                  onTap: () {
                                    if (isPlaylistPlaying) {
                                      ref.read(playerProvider.notifier).togglePlayPause();
                                    } else if (songs.isNotEmpty) {
                                      ref.read(playerProvider.notifier).playQueue(songs, startIndex: 0);
                                    }
                                  },
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      color: BopTheme.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlaylistPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.black,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      final isPlaying = playerState.currentSong?.id == song.id;

                      return ListTile(
                        leading: isPlaying ? AnimatedEqualizer(color: BopTheme.green, size: 16) : null,
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isPlaying ? BopTheme.green : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(color: BopTheme.textSecondary, fontSize: 12),
                          maxLines: 1,
                        ),
                        trailing: isPlaying && playerState.isPlaying
                          ? AnimatedEqualizer(color: BopTheme.green, size: 16)
                          : null,
                        onTap: () {
                          ref.read(playerProvider.notifier).playQueue(songs, startIndex: index);
                        },
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
