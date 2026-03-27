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

class ArtistScreen extends ConsumerStatefulWidget {
  final String artistName;

  const ArtistScreen({
    super.key,
    required this.artistName,
  });

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen>
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
      backgroundColor: BopTheme.background,
      body: allSongs.when(
        data: (songs) {
          final artistSongs = songs
              .where((s) => s.artist.toLowerCase() == widget.artistName.toLowerCase())
              .toList();

          final artSong = artistSongs.cast<Song?>().firstWhere(
            (s) => s!.artBytes != null && s.artBytes!.isNotEmpty,
            orElse: () => null,
          );
          final artBytes = artSong?.artBytes;

          if (artBytes != null && artBytes.isNotEmpty) {
            _extractColor(artBytes);
          }

          final isArtistPlaying = artistSongs.any(
              (s) => s.id == playerState.currentSong?.id) && playerState.isPlaying;

          if (isArtistPlaying) {
            _playPauseController.forward();
          } else {
            _playPauseController.reverse();
          }

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
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
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _dominantColor.withOpacity(0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: artBytes == null || artBytes.isEmpty
                                          ? Container(
                                              color: _dominantColor.withOpacity(0.5),
                                              child: const Icon(Icons.person, color: Colors.white38, size: 64),
                                            )
                                          : Image.memory(
                                              Uint8List.fromList(artBytes),
                                              key: ValueKey('artist_screen_${widget.artistName}'),
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                              cacheWidth: 360,
                                              cacheHeight: 360,
                                            ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  widget.artistName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${artistSongs.length} songs',
                                style: const TextStyle(
                                  color: BopTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () {
                                        if (isArtistPlaying) {
                                          ref.read(playerProvider.notifier).togglePlayPause();
                                        } else if (artistSongs.isNotEmpty) {
                                          ref.read(playerProvider.notifier).playQueue(artistSongs, startIndex: 0);
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
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = artistSongs[index];
                          final isPlaying = playerState.currentSong?.id == song.id;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: SizedBox(
                              width: 24,
                              child: Center(
                                child: isPlaying && playerState.isPlaying
                                    ? const AnimatedEqualizer(color: BopTheme.green, size: 18)
                                    : isPlaying
                                        ? const Icon(Icons.equalizer, color: BopTheme.green, size: 18)
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
                                color: isPlaying ? BopTheme.green : BopTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.album,
                              style: const TextStyle(
                                color: BopTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            onTap: () {
                              ref.read(playerProvider.notifier).playQueue(artistSongs, startIndex: index);
                            },
                          );
                        },
                        childCount: artistSongs.length,
                      ),
                    ),
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
          child: Text('Error loading artist', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
