// widgets/mini_player.dart
// Persistent mini player bar at the bottom of every tab screen.
// Features: rounded corners, cover-based gradient, marquee text, progress bar.
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:text_scroll/text_scroll.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../screens/player/now_playing_screen.dart';

/// Caches extracted dominant color per song id to avoid re-computing.
final _colorCache = <int, Color>{};

Future<Color> _extractDominantColor(List<int> artBytes) async {
  final imageProvider = MemoryImage(Uint8List.fromList(artBytes));
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      imageProvider,
      maximumColorCount: 6,
      size: const Size(50, 50),
    );
    return palette.dominantColor?.color ?? BopTheme.surface;
  } catch (_) {
    return BopTheme.surface;
  }
}

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  Color _dominantColor = BopTheme.surface;

  int? _lastSongId;

  void _updateColor(int songId, List<int> artBytes) async {
    if (_lastSongId == songId) return;
    _lastSongId = songId;

    if (_colorCache.containsKey(songId)) {
      if (mounted) setState(() => _dominantColor = _colorCache[songId]!);
      return;
    }

    final color = await _extractDominantColor(artBytes);
    _colorCache[songId] = color;
    if (mounted) setState(() => _dominantColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    // Don't show if nothing is playing
    if (song == null) return const SizedBox.shrink();

    // Extract color from art
    if (song.artBytes != null && song.artBytes!.isNotEmpty) {
      _updateColor(song.id, song.artBytes!);
    }

    final position = playerState.position;
    final duration = playerState.duration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NowPlayingScreen(song: song)),
          );
        }
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NowPlayingScreen(song: song),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                _dominantColor.withOpacity(0.85),
                _dominantColor.withOpacity(0.4),
                BopTheme.surface.withOpacity(0.95),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
              child: Row(
                children: [
                  // Album art thumb
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: song.artBytes != null && song.artBytes!.isNotEmpty
                          ? Image.memory(
                              Uint8List.fromList(song.artBytes!),
                              key: ValueKey('mini_art_${song.id}'),
                              cacheWidth: 84, // 42 * devicePixelRatio (approx 2.0)
                              cacheHeight: 84,
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
                  const SizedBox(width: 10),

                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextScroll(song.title,
                            velocity: const Velocity(
                                pixelsPerSecond: Offset(30, 0)),
                            delayBefore: const Duration(seconds: 2),
                            pauseBetween: const Duration(seconds: 2),
                            style: const TextStyle(
                                color: BopTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(song.artist,
                            style: const TextStyle(
                                color: BopTheme.textSecondary,
                                fontSize: 10)),
                      ],
                    ),
                  ),

                  // Play/Pause button
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                        key: ValueKey(playerState.isPlaying),
                        color: BopTheme.textPrimary,
                      ),
                    ),
                    onPressed: () {
                      ref.read(playerProvider.notifier).togglePlayPause();
                    },
                  ),

                  // Skip next
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: BopTheme.textSecondary),
                    onPressed: () {
                      ref.read(playerProvider.notifier).skipNext();
                    },
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(BopTheme.green),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
