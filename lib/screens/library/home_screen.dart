// screens/library/home_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/stats_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/mini_player.dart';
import '../player/now_playing_screen.dart';
import '../../models/song.dart';
import '../profile/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSongs = ref.watch(recentSongsProvider);
    final topArtists = ref.watch(topArtistsProvider);
    final topSongs = ref.watch(songCountProvider); // We'll just use the first song from recent for now or top

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 20),
            children: [
              // ── Greeting ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: BeatSpillTheme.textSecondary),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Recently played row ───────────────
              Text('Recently played',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: recentSongs.when(
                  data: (songs) {
                    if (songs.isEmpty) {
                      return const Center(
                        child: Text('Play some songs to see them here',
                            style: TextStyle(
                                color: BeatSpillTheme.textMuted,
                                fontSize: 11)),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: songs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final song = songs[i];
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(playerProvider.notifier)
                                .playQueue(songs, startIndex: i);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NowPlayingScreen(song: song),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: song.artBytes != null && song.artBytes!.isNotEmpty
                                      ? Image.memory(
                                          Uint8List.fromList(
                                              song.artBytes!),
                                          key: ValueKey('home_art_${song.id}'),
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        )
                                      : Container(
                                          color: _colorForIndex(i),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  song.title,
                                  style: const TextStyle(
                                      color: BeatSpillTheme.textSecondary,
                                      fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Your Wrapped ──────────────────────
              Text('Your Wrapped',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Expanded(
                      child: _WrappedShortcut(
                        label: 'Top Songs',
                        onTap: () {
                          ref.read(statsPeriodProvider.notifier).state = StatsPeriod.month;
                          ref.read(shellTabIndexProvider.notifier).state = 2; // Stats tab
                        },
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E8B57), Color(0xFF1A1A1A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WrappedShortcut(
                        label: 'Top Artists',
                        onTap: () {
                          ref.read(statsPeriodProvider.notifier).state = StatsPeriod.month;
                          ref.read(shellTabIndexProvider.notifier).state = 2; // Stats tab
                        },
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE74C3C), Color(0xFF8E44AD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Editor's picks ────────────────────
              Text("Editor's picks",
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const _EditorPicksRow(),
              const SizedBox(height: 100), // Extra space to scroll past miniplayer
            ],
          ),
        ),
        const MiniPlayer(),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _colorForIndex(int i) {
    const colors = [
      Color(0xFFC0392B),
      Color(0xFF8E44AD),
      Color(0xFF2C3E50),
      Color(0xFF1A3A5C),
      Color(0xFF2D6A4F),
    ];
    return colors[i % colors.length];
  }
}

class _WrappedShortcut extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _WrappedShortcut({required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Abstract geometric pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorPicksRow extends ConsumerWidget {
  const _EditorPicksRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picksAsync = ref.watch(editorPicksProvider);

    return SizedBox(
      height: 135,
      child: picksAsync.when(
        data: (songs) {
          if (songs.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final song = songs[i];
              return GestureDetector(
                onTap: () {
                  ref.read(playerProvider.notifier).playQueue(songs, startIndex: i);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NowPlayingScreen(song: song),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: BeatSpillTheme.surface,
                        child: song.artBytes != null && song.artBytes!.isNotEmpty
                            ? Image.memory(
                                Uint8List.fromList(song.artBytes!),
                                key: ValueKey('pick_art_${song.id}'),
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                            : Center(
                                child: Icon(Icons.music_note, color: Colors.white24, size: 32),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      child: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        song.artist,
                        style: const TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
