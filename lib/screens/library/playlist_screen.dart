// screens/library/playlist_screen.dart
// Full playlist detail screen — shows 4-tile art, metadata, and all songs.
// Uses cover art color extraction for gradient, animated play button, animated equalizer.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../theme/app_theme.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/animated_equalizer.dart';
import '../../widgets/playlist_cover_widget.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistScreen({
    super.key,
    required this.playlist,
  });

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen>
    with SingleTickerProviderStateMixin {
  Color _dominantColor = const Color(0xFF333333);
  bool _colorExtracted = false;
  late AnimationController _playPauseController;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Try to extract from coverColor initially
    try {
      _dominantColor = Color(
          int.parse(widget.playlist.coverColor.replaceFirst('#', '0xFF')));
    } catch (_) {}
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    super.dispose();
  }

  Future<void> _extractColor(List<int> artBytes) async {
    if (_colorExtracted) return;
    _colorExtracted = true;
    final provider = MemoryImage(Uint8List.fromList(artBytes));
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 6,
        size: const Size(80, 80),
      );
      final color = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          _dominantColor;
      if (mounted) setState(() => _dominantColor = color);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the playlist songs are fully loaded if managed by Isar relations
    ref.watch(allSongsProvider);
    final playlistSongs = widget.playlist.songs.toList();
    final playerState = ref.watch(playerProvider);

    // Try extracting color from first song's art
    final artSong = playlistSongs.cast<Song?>().firstWhere(
      (s) => s!.artBytes != null && s.artBytes!.isNotEmpty,
      orElse: () => null,
    );
    if (artSong?.artBytes != null && artSong!.artBytes!.isNotEmpty) {
      _extractColor(artSong.artBytes!);
    }

    // Check if this playlist is currently playing
    final isPlaylistPlaying = playlistSongs.any(
        (s) => s.id == playerState.currentSong?.id) && playerState.isPlaying;

    if (isPlaylistPlaying) {
      _playPauseController.forward();
    } else {
      _playPauseController.reverse();
    }

    return Scaffold(
      backgroundColor: BopTheme.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Header with playlist art ────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_dominantColor, BopTheme.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Playlist art
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _dominantColor.withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 180,
                                height: 180,
                                child: PlaylistCoverWidget(playlist: widget.playlist, size: 180),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Playlist name
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              widget.playlist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtitle area
                          const Text(
                            'Playlist',
                            style: TextStyle(
                              color: BopTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${playlistSongs.length} songs',
                            style: const TextStyle(
                              color: BopTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Play all button with animation
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () {
                                    if (isPlaylistPlaying) {
                                      ref.read(playerProvider.notifier).togglePlayPause();
                                    } else if (playlistSongs.isNotEmpty) {
                                      ref
                                          .read(playerProvider.notifier)
                                          .playQueue(playlistSongs, startIndex: 0);
                                    }
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: BopTheme.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: AnimatedIcon(
                                        icon: AnimatedIcons.play_pause,
                                        progress: _playPauseController,
                                        color: Colors.black,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Song list ─────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = playlistSongs[index];
                      final isPlaying = playerState.currentSong?.id == song.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        leading: SizedBox(
                          width: 24,
                          child: Center(
                            child: isPlaying && playerState.isPlaying
                                ? const AnimatedEqualizer(
                                    color: BopTheme.green, size: 18)
                                : isPlaying
                                    ? const Icon(Icons.equalizer,
                                        color: BopTheme.green, size: 18)
                                    : Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: BopTheme.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isPlaying
                                ? BopTheme.green
                                : BopTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(
                            color: BopTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        // Removed 3-dots here as well, per request
                        onTap: () {
                          ref
                              .read(playerProvider.notifier)
                              .playQueue(playlistSongs, startIndex: index);
                        },
                      );
                    },
                    childCount: playlistSongs.length,
                  ),
                ),
                // Bottom spacing for mini player
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
