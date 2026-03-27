// screens/player/now_playing_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../services/db_service.dart';
import '../../widgets/song_option_widgets.dart';
import '../../services/lrc_parser.dart';
import '../../providers/stats_provider.dart';
import '../library/album_screen.dart';
import 'lyrics_screen.dart';

/// Color cache so we don't re-extract for the same song
final _dominantColorCache = <int, Color>{};

Future<Color> _extractColor(List<int> artBytes) async {
  final provider = MemoryImage(Uint8List.fromList(artBytes));
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      provider,
      maximumColorCount: 6,
      size: const Size(80, 80),
    );
    return palette.dominantColor?.color ??
        palette.vibrantColor?.color ??
        const Color(0xFF333333);
  } catch (_) {
    return const Color(0xFF333333);
  }
}

class NowPlayingScreen extends ConsumerStatefulWidget {
  final Song song;
  const NowPlayingScreen({super.key, required this.song});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  Color _dominantColor = const Color(0xFF333333);
  late AnimationController _playPauseController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageController = PageController(initialPage: ref.read(playerProvider).currentIndex);
    _extractDominant(widget.song);
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _extractDominant(Song song) async {
    if (song.artBytes == null || song.artBytes!.isEmpty) return;
    if (_dominantColorCache.containsKey(song.id)) {
      setState(() => _dominantColor = _dominantColorCache[song.id]!);
      return;
    }
    final color = await _extractColor(song.artBytes!);
    _dominantColorCache[song.id] = color;
    if (mounted) setState(() => _dominantColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong ?? widget.song;
    final isPlaying = playerState.isPlaying;
    final position = playerState.position;
    final duration = playerState.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    // Using ref.listen for side effects is more efficient than build-time checks
    ref.listen(playerProvider, (previous, next) {
      if (previous?.currentSong?.id != next.currentSong?.id) {
        if (next.currentSong != null) _extractDominant(next.currentSong!);
      }
      
      if (previous?.isPlaying != next.isPlaying) {
        if (next.isPlaying) _playPauseController.forward();
        else _playPauseController.reverse();
      }

      if (_pageController.hasClients && next.currentIndex != _pageController.page?.round()) {
         _pageController.animateToPage(
          next.currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _dominantColor,
              _dominantColor.withOpacity(0.6),
              BopTheme.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.35, 0.75],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Flexible(
                      child: Text(
                        song.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz,
                          color: Colors.white),
                      onPressed: () => _showContextMenu(context, song),
                    ),
                  ],
                ),
              ),

              // ── Album art ─────────────────────────────
              Expanded(
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PageView.builder(
                        itemCount: playerState.queue.isEmpty ? 1 : playerState.queue.length,
                        controller: _pageController,
                        onPageChanged: (index) {
                          if (index != playerState.currentIndex) {
                            ref.read(playerProvider.notifier).skipTo(index);
                          }
                        },
                        itemBuilder: (context, index) {
                          final displaySong = playerState.queue.isEmpty ? song : playerState.queue[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _dominantColor.withOpacity(0.4),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: displaySong.artBytes != null && displaySong.artBytes!.isNotEmpty
                                  ? Image.memory(
                                      Uint8List.fromList(displaySong.artBytes!),
                                      key: ValueKey('art_${displaySong.id}'),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      cacheWidth: 600,
                                      cacheHeight: 600,
                                    )
                                  : _PlaceholderArt(title: displaySong.title),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (playerState.djTransitionMsg != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: BopTheme.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: BopTheme.green.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: BopTheme.green, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  playerState.djTransitionMsg!,
                                  style: const TextStyle(color: BopTheme.green, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Title + like ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextScroll(song.title,
                              velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                              delayBefore: const Duration(seconds: 2),
                              pauseBetween: const Duration(seconds: 2),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  )),
                          const SizedBox(height: 2),
                          Text(song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        song.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: song.isLiked
                            ? BopTheme.green
                            : BopTheme.textSecondary,
                      ),
                      onPressed: () {
                        ref.read(playerProvider.notifier).toggleLike();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Progress bar ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: SliderComponentShape.noOverlay,
                        activeTrackColor: BopTheme.textPrimary,
                        inactiveTrackColor: BopTheme.textMuted,
                        thumbColor: BopTheme.textPrimary,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) {
                          final newPos = Duration(
                            milliseconds: (v * duration.inMilliseconds).toInt(),
                          );
                          ref.read(playerProvider.notifier).seek(newPos);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position),
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(_formatDuration(duration),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Controls ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle,
                          color: playerState.shuffleEnabled
                              ? BopTheme.green
                              : BopTheme.textSecondary),
                      onPressed: () {
                        ref.read(playerProvider.notifier).toggleShuffle();
                      },
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous, color: BopTheme.textPrimary),
                      onPressed: () {
                        ref.read(playerProvider.notifier).skipPrevious();
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(playerProvider.notifier).togglePlayPause();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: BopTheme.textPrimary,
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
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next, color: BopTheme.textPrimary),
                      onPressed: () {
                        ref.read(playerProvider.notifier).skipNext();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        playerState.repeatMode == PlayerRepeatMode.one 
                            ? Icons.repeat_one 
                            : Icons.repeat,
                        color: playerState.repeatMode != PlayerRepeatMode.off
                            ? BopTheme.green
                            : Colors.white24,
                        size: 22,
                      ),
                      onPressed: () {
                        ref.read(playerProvider.notifier).toggleRepeat();
                      },
                    ),
                  ],
                ),
              ),

              // ── Lyrics Peek Card ─────────────────────
              _LyricsPeek(song: song, dominantColor: _dominantColor),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ContextMenu(song: song),
    );
  }

  String _formatDuration(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

// ── Placeholder album art ─────────────────────────────────────
class _PlaceholderArt extends StatelessWidget {
  final String title;
  const _PlaceholderArt({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFC0392B),
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0] : '♪',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF1C40F),
          ),
        ),
      ),
    );
  }
}

// ── Context menu bottom sheet ─────────────────────────────────
class _ContextMenu extends ConsumerWidget {
  final Song song;
  const _ContextMenu({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final currentSongRef = playerState.currentSong;
    final currentSong = (currentSongRef != null && currentSongRef.id == song.id)
        ? currentSongRef
        : song;

    final items = [
      (
        currentSong.isLiked ? Icons.favorite : Icons.favorite_border,
        currentSong.isLiked ? 'Unlike' : 'Like',
        () => ref.read(playerProvider.notifier).toggleLike()
      ),
      (Icons.playlist_add, 'Add to playlist', () {
        _showPlaylistSelector(context, ref, currentSong);
      }),
      (Icons.queue_music, 'Add to queue', () {
        ref.read(playerProvider.notifier).addToQueue(currentSong);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song added to queue')),
        );
      }),
      (Icons.share, 'Share', () {
        Share.share('Check out this song: ${currentSong.title} by ${currentSong.artist}');
      }),
      (Icons.album, 'View album', () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumScreen(albumName: currentSong.album, artist: currentSong.artist),
          ),
        );
      }),
      (Icons.info_outline, 'Song credits', () {
        _showCreditsDialog(context, currentSong);
      }),
      (Icons.timer, 'Sleep timer', () {
        _showSleepTimerSelector(context, ref);
      }),
      (Icons.remove_circle_outline, 'Remove from library', () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF282828),
            title: const Text('Remove Song', style: TextStyle(color: Colors.white)),
            content: Text('Remove "${currentSong.title}" from your library? The file will not be deleted from your device.',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: BopTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove', style: TextStyle(color: BopTheme.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await DbService.instance.hideSong(currentSong.id);
          if (context.mounted) {
            ref.read(playerProvider.notifier).removeSong(currentSong.id);
            ref.invalidate(allSongsProvider);
            ref.invalidate(likedSongsProvider);
            ref.invalidate(recentSongsProvider);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song removed from library')));
          }
        }
        if (context.mounted) {
          Navigator.pop(context); // Close the bottom sheet
        }
      }),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: currentSong.artBytes != null && currentSong.artBytes!.isNotEmpty
                        ? Image.memory(
                            Uint8List.fromList(currentSong.artBytes!),
                            key: ValueKey('ctx_art_${currentSong.id}'),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: 100,
                            cacheHeight: 100,
                          )
                        : const ColoredBox(color: Color(0xFFC0392B)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentSong.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(currentSong.artist,
                          style: const TextStyle(
                              color: BopTheme.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF333333), height: 1),
          ...items.map((item) => ListTile(
                leading: Icon(item.$1,
                    color: item.$2 == 'Unlike'
                        ? BopTheme.green
                        : BopTheme.textSecondary,
                    size: 20),
                title: Text(item.$2,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  item.$3();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PlaylistSelector(song: song),
    );
  }

  void _showSleepTimerSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const SleepTimerSelector(),
    );
  }

  void _showCreditsDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Song Credits', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${song.title}', style: const TextStyle(color: Colors.white70)),
            Text('Artist: ${song.artist}', style: const TextStyle(color: Colors.white70)),
            Text('Album: ${song.album}', style: const TextStyle(color: Colors.white70)),
            if (song.genre.isNotEmpty)
              Text('Genre: ${song.genre}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text('Source: Local File', style: TextStyle(color: BopTheme.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: BopTheme.green)),
          ),
        ],
      ),
    );
  }
}

// ── Lyrics Peek Widget ────────────────────────────────────────
class _LyricsPeek extends ConsumerStatefulWidget {
  final Song song;
  final Color dominantColor;
  const _LyricsPeek({required this.song, required this.dominantColor});

  @override
  ConsumerState<_LyricsPeek> createState() => _LyricsPeekState();
}

class _LyricsPeekState extends ConsumerState<_LyricsPeek> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(lyricsProvider(widget.song));
    // Optimization: Selective watching to avoid rebuilding entire peek widget on every position update
    final position = ref.watch(playerProvider.select((s) => s.position));

    // Use the dominant color for the lyrics card
    final cardColor = HSLColor.fromColor(widget.dominantColor)
        .withLightness(0.25)
        .withSaturation(0.6)
        .toColor();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LyricsScreen(song: widget.song),
            ),
          );
        },
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: lyricsAsync.when(
            data: (lyrics) {
              if (lyrics == null || lyrics.isEmpty) return _peekPlaceholder();
              final lines = LrcParser.parse(lyrics);
              if (lines.isEmpty) return _peekPlaceholder();

              int activeIndex = -1;
              final adjustedPosition = position;
              for (int i = 0; i < lines.length; i++) {
                if (adjustedPosition >= lines[i].timestamp) activeIndex = i;
                else break;
              }

              // Centering scroll logic for peek
              if (activeIndex != _currentIndex && activeIndex != -1) {
                _currentIndex = activeIndex;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    const lineHeight = 44.0;
                    final target = (activeIndex * lineHeight) - 58.0;
                    _scrollController.animateTo(
                      target.clamp(0, _scrollController.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Lyrics',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5)),
                        Icon(Icons.fullscreen, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                    Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: lines.length,
                      itemBuilder: (_, i) {
                        final isActive = i == activeIndex;
                        final distance = (i - activeIndex).abs();
                        final targetOpacity = isActive ? 1.0 : (distance == 1 ? 0.55 : 0.25);
                        final targetSize = isActive ? 18.0 : 15.0;

                        return TweenAnimationBuilder<double>(
                          tween: Tween(end: targetOpacity),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, opacity, _) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(end: targetSize),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              builder: (context, fontSize, _) {
                                return Container(
                                  height: 44,
                                  alignment: Alignment.centerLeft,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: Text(
                                      lines[i].text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
            error: (_, __) => _peekPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _peekPlaceholder() {
    return const Center(
      child: Text('Lyrics aren\'t available for this song',
          style: TextStyle(color: Colors.white54, fontSize: 12)),
    );
  }
}
