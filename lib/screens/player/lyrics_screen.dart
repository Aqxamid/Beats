import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/song.dart';
import '../../providers/stats_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/lrc_parser.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  final Song song;
  const LyricsScreen({super.key, required this.song});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
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

    return Scaffold(
      backgroundColor: BeatSpillTheme.background,
      body: SafeArea(
        child: lyricsAsync.when(
          data: (lyrics) {
            if (lyrics == null || lyrics.isEmpty) {
              return _emptyState();
            }

            final lines = LrcParser.parse(lyrics);
            if (lines.isEmpty) return _emptyState();

            // Find current active line
            int activeIndex = -1;
            for (int i = 0; i < lines.length; i++) {
              if (position >= lines[i].timestamp) {
                activeIndex = i;
              } else {
                break;
              }
            }

            // Auto-scroll logic: centers the active line in the viewport
            if (activeIndex != _currentIndex && activeIndex != -1) {
              _currentIndex = activeIndex;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  final viewportHeight = _scrollController.position.viewportDimension;
                  final lineHeight = 60.0; // matched with padding/font
                  final targetOffset = (activeIndex * lineHeight) - (viewportHeight / 2) + (lineHeight / 2);
                  
                  _scrollController.animateTo(
                    targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                  );
                }
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: BeatSpillTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    itemCount: lines.length,
                    itemBuilder: (_, i) {
                      final isActive = i == activeIndex;
                      return GestureDetector(
                        onTap: () {
                          if (lines[i].timestamp != Duration.zero) {
                            ref.read(playerProvider.notifier).seek(lines[i].timestamp);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            lines[i].text,
                            style: TextStyle(
                              fontSize: isActive ? 24 : 18,
                              fontWeight:
                                  isActive ? FontWeight.w800 : FontWeight.w600,
                              color: isActive
                                  ? BeatSpillTheme.textPrimary
                                  : BeatSpillTheme.textSecondary.withOpacity(0.4),
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: BeatSpillTheme.green),
          ),
          error: (e, __) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: BeatSpillTheme.red)),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Text('Lyrics not available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: BeatSpillTheme.textMuted)),
          const SizedBox(height: 8),
          Text(widget.song.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
