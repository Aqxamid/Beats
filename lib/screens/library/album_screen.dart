// screens/library/album_screen.dart
// Full album detail screen — shows album art, metadata, and all songs.
// Uses cover art color extraction for gradient, animated play button, animated equalizer.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../theme/app_theme.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/animated_equalizer.dart';
import '../player/now_playing_screen.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  final String albumName;
  final String artist;

  const AlbumScreen({
    super.key,
    required this.albumName,
    required this.artist,
  });

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen>
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
          const Color(0xFF333333);
      if (mounted) setState(() => _dominantColor = color);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final allSongs = ref.watch(allSongsProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: BeatSpillTheme.background,
      body: allSongs.when(
        data: (songs) {
          final albumSongs = songs
              .where((s) => s.album.toLowerCase() == widget.albumName.toLowerCase())
              .toList();

          // Find album art from first song with artwork
          final artSong = albumSongs.cast<Song?>().firstWhere(
            (s) => s!.artBytes != null && s.artBytes!.isNotEmpty,
            orElse: () => null,
          );
          final artBytes = artSong?.artBytes;

          // Extract color from actual cover art
          if (artBytes != null && artBytes.isNotEmpty) {
            _extractColor(artBytes);
          }

          // Check if this album is currently playing
          final isAlbumPlaying = albumSongs.any(
              (s) => s.id == playerState.currentSong?.id) && playerState.isPlaying;

          if (isAlbumPlaying) {
            _playPauseController.forward();
          } else {
            _playPauseController.reverse();
          }

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // ── Header with album art ────────────
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_dominantColor, BeatSpillTheme.background],
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
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                                // Album art
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
                                      child: artBytes == null || artBytes.isEmpty
                                          ? Container(
                                              color: _dominantColor.withOpacity(0.5),
                                              child: const Icon(Icons.album,
                                                  color: Colors.white38, size: 64),
                                            )
                                          : Image.memory(
                                              Uint8List.fromList(artBytes),
                                              key: ValueKey('album_screen_${widget.albumName}'),
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // Album name
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  widget.albumName,
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
                              // Artist
                              Text(
                                widget.artist,
                                style: const TextStyle(
                                  color: BeatSpillTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${albumSongs.length} songs',
                                style: const TextStyle(
                                  color: BeatSpillTheme.textMuted,
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
                                    GestureDetector(
                                      onTap: () {
                                        if (isAlbumPlaying) {
                                          ref.read(playerProvider.notifier).togglePlayPause();
                                        } else if (albumSongs.isNotEmpty) {
                                          ref
                                              .read(playerProvider.notifier)
                                              .playQueue(albumSongs,
                                                  startIndex: 0);
                                        }
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          color: BeatSpillTheme.green,
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
                          final song = albumSongs[index];
                          final isPlaying =
                              playerState.currentSong?.id == song.id;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            leading: SizedBox(
                              width: 24,
                              child: Center(
                                child: isPlaying && playerState.isPlaying
                                    ? const AnimatedEqualizer(
                                        color: BeatSpillTheme.green, size: 18)
                                    : isPlaying
                                        ? const Icon(Icons.equalizer,
                                            color: BeatSpillTheme.green, size: 18)
                                        : Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: BeatSpillTheme.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: isPlaying
                                    ? BeatSpillTheme.green
                                    : BeatSpillTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              style: const TextStyle(
                                color: BeatSpillTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            onTap: () {
                              ref
                                  .read(playerProvider.notifier)
                                  .playQueue(albumSongs, startIndex: index);
                            },
                          );
                        },
                        childCount: albumSongs.length,
                      ),
                    ),
                    // Bottom spacing for mini player
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              ),
              const MiniPlayer(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Error loading album',
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
