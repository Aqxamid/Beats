// widgets/mini_player.dart
// Persistent mini player bar at the bottom of every tab screen.
// Tapping it pushes NowPlayingScreen.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_scroll/text_scroll.dart';
import '../theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../screens/player/now_playing_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    // Don't show if nothing is playing
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // swipe up corresponds to negative velocity
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NowPlayingScreen(song: song)),
          );
        }
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NowPlayingScreen(song: song),
          ),
        );
      },
      child: Container(
        color: BeatSpillTheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Album art thumb
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 36,
                height: 36,
                child: song.artBytes != null && song.artBytes!.isNotEmpty
                    ? Image.memory(
                        Uint8List.fromList(song.artBytes!),
                        key: ValueKey('mini_art_${song.id}'),
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
                      velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                      delayBefore: const Duration(seconds: 2),
                      pauseBetween: const Duration(seconds: 2),
                      style: const TextStyle(
                          color: BeatSpillTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  Text(song.artist,
                      style: const TextStyle(
                          color: BeatSpillTheme.textSecondary, fontSize: 10)),
                ],
              ),
            ),

            // Play/Pause button
            IconButton(
              icon: Icon(
                playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                color: BeatSpillTheme.textPrimary,
              ),
              onPressed: () {
                ref.read(playerProvider.notifier).togglePlayPause();
              },
            ),

            // Skip next
            IconButton(
              icon: const Icon(Icons.skip_next,
                  color: BeatSpillTheme.textSecondary),
              onPressed: () {
                ref.read(playerProvider.notifier).skipNext();
              },
            ),
          ],
        ),
      ),
    );
  }
}
