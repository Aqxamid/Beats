// screens/player/now_playing_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../services/db_service.dart';
import '../../widgets/song_option_widgets.dart';
import '../../services/lrc_parser.dart';
import '../../providers/stats_provider.dart';
import 'lyrics_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  final Song song;
  const NowPlayingScreen({super.key, required this.song});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  @override
  void initState() {
    super.initState();
    // If this song isn't already playing, start it
    final current = ref.read(playerProvider).currentSong;
    if (current == null || current.id != widget.song.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(playerProvider.notifier).play(widget.song);
      });
    }
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

    return Scaffold(
      backgroundColor: BeatSpillTheme.background,
      body: SafeArea(
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
                        color: BeatSpillTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    song.album,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: BeatSpillTheme.textSecondary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz,
                        color: BeatSpillTheme.textSecondary),
                    onPressed: () => _showContextMenu(context, song),
                  ),
                ],
              ),
            ),

            // ── Album art ─────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.artBytes != null && song.artBytes!.isNotEmpty
                        ? Image.memory(
                            Uint8List.fromList(song.artBytes!),
                            key: ValueKey('art_${song.id}'),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : _PlaceholderArt(title: song.title),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: BeatSpillTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      song.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: song.isLiked
                          ? BeatSpillTheme.green
                          : BeatSpillTheme.textSecondary,
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
                      activeTrackColor: BeatSpillTheme.textPrimary,
                      inactiveTrackColor: BeatSpillTheme.textMuted,
                      thumbColor: BeatSpillTheme.textPrimary,
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
                            ? BeatSpillTheme.green
                            : BeatSpillTheme.textSecondary),
                    onPressed: () {
                      ref.read(playerProvider.notifier).toggleShuffle();
                    },
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous, color: BeatSpillTheme.textPrimary),
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
                        color: BeatSpillTheme.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next, color: BeatSpillTheme.textPrimary),
                    onPressed: () {
                      ref.read(playerProvider.notifier).skipNext();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.repeat,
                        color: playerState.repeatMode != PlayerRepeatMode.off
                            ? BeatSpillTheme.green
                            : BeatSpillTheme.textSecondary),
                    onPressed: () {
                      ref.read(playerProvider.notifier).toggleRepeat();
                    },
                  ),
                ],
              ),
            ),

            // ── Lyrics Peek Card ─────────────────────
            _LyricsPeek(song: song),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Showing all songs from album: ${currentSong.album}')),
        );
      }),
      (Icons.info_outline, 'Song credits', () {
        _showCreditsDialog(context, currentSong);
      }),
      (Icons.timer, 'Sleep timer', () {
        _showSleepTimerSelector(context, ref);
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
                              color: BeatSpillTheme.textSecondary,
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
                        ? BeatSpillTheme.green
                        : BeatSpillTheme.textSecondary,
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
            const Text('Source: Local File', style: TextStyle(color: BeatSpillTheme.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: BeatSpillTheme.green)),
          ),
        ],
      ),
    );
  }
}

// ── Lyrics Peek Widget ────────────────────────────────────────
class _LyricsPeek extends ConsumerStatefulWidget {
  final Song song;
  const _LyricsPeek({required this.song});

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
    final position = ref.watch(playerProvider).position;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GestureDetector(
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
            color: const Color(0xFFC44D20), // Premium Burnt Orange
            borderRadius: BorderRadius.circular(12),
          ),
          child: lyricsAsync.when(
            data: (lyrics) {
              if (lyrics == null || lyrics.isEmpty) return _peekPlaceholder();
              final lines = LrcParser.parse(lyrics);
              if (lines.isEmpty) return _peekPlaceholder();

              int activeIndex = -1;
              for (int i = 0; i < lines.length; i++) {
                if (position >= lines[i].timestamp) activeIndex = i;
                else break;
              }

              // Centering scroll logic for peek
              if (activeIndex != _currentIndex && activeIndex != -1) {
                _currentIndex = activeIndex;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    const lineHeight = 44.0;
                    final target = (activeIndex * lineHeight) - 58.0; // center in 160 height
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
                        return Container(
                          height: 44,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            lines[i].text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isActive ? 18 : 15,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
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

