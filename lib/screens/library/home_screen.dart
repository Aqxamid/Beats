// screens/library/home_screen.dart
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'smart_playlist_screen.dart';
import '../../theme/app_theme.dart';
import '../../providers/stats_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/song.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/playlist_collage.dart';
import '../player/now_playing_screen.dart';
import '../profile/settings_screen.dart';
import '../../services/db_service.dart';
import '../../models/playlist.dart';

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
                    icon: Icon(Icons.settings, color: BopTheme.textSecondary),
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
                      return Center(
                        child: Text('Play some songs to see them here',
                            style: TextStyle(
                                color: BopTheme.textMuted,
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
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
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
                                          cacheWidth: 96,
                                          cacheHeight: 96,
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
                                  style: TextStyle(
                                      color: BopTheme.textSecondary,
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
                  skipLoadingOnReload: true,
                ),
              ),
              const SizedBox(height: 20),

              // ── Bop Recap ─────────────────────────
              Text('Bop Recap',
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
                      child: _RecapShortcut(
                        label: 'Top Songs',
                        type: _ShortcutType.circles,
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
                      child: _RecapShortcut(
                        label: 'Top Artists',
                        type: _ShortcutType.rects,
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

              // ── AI Curated Playlists ────────────────────
              Text("AI Curated Playlists",
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const _AiPlaylistsRow(),
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

enum _ShortcutType { circles, rects }

class _RecapShortcut extends ConsumerWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  final _ShortcutType type;
  const _RecapShortcut({required this.label, required this.gradient, required this.onTap, this.type = _ShortcutType.circles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final isBold = ref.watch(boldDesignProvider);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: isBold ? null : gradient,
          color: isBold ? gradient.colors.first : null,
          borderRadius: BorderRadius.circular(isBold ? 0 : 8),
          border: isBold ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Stack(
          children: [
            if (true) ...[
              if (type == _ShortcutType.circles) ...[
                 Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.12)),
                  ),
                ),
                Positioned(
                  left: -10,
                  bottom: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.1)),
                  ),
                ),
              ] else ...[
                 Positioned(
                  right: -10,
                  bottom: -10,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                ),
                 Positioned(
                  left: 10,
                  top: -20,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black.withOpacity(0.08)),
                    ),
                  ),
                ),
              ],
            ],
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
              return InkWell(
                borderRadius: BorderRadius.circular(8),
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
                        color: BopTheme.surface,
                        child: song.artBytes != null && song.artBytes!.isNotEmpty
                            ? Image.memory(
                                Uint8List.fromList(song.artBytes!),
                                key: ValueKey('pick_art_${song.id}'),
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                cacheWidth: 160,
                                cacheHeight: 160,
                              )
                            : Center(
                                child: Icon(Icons.music_note, color: Colors.white10, size: 32),
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
                        style: TextStyle(color: BopTheme.textSecondary, fontSize: 9),
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
        skipLoadingOnReload: true,
      ),
    );
  }
}

class _AiPlaylistsRow extends ConsumerWidget {
  const _AiPlaylistsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiAsync = ref.watch(aiPlaylistsProvider);
    final isBold = ref.watch(boldDesignProvider);

    return SizedBox(
      height: 135,
      child: aiAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final playlist = playlists[i];
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmartPlaylistScreen(playlist: playlist),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: isBold 
                                ? LinearGradient(
                                    colors: playlist.isAiGenerated 
                                      ? [const Color(0xFFE91E63), const Color(0xFF9C27B0)] // Vibrant Pink/Purple
                                      : [const Color(0xFFFF9800), const Color(0xFFF44336)], // Vibrant Orange/Red
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: playlist.isAiGenerated
                                      ? [const Color(0xFF1DB954), const Color(0xFF191414)] // Classic Green/Black
                                      : [const Color(0xFF3F51B5), const Color(0xFF212121)], // Vibrant Blue/Dark
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                              borderRadius: isBold ? BorderRadius.zero : BorderRadius.circular(4),
                              border: isBold ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                            child: PlaylistCollage(
                              songs: playlist.songs,
                              size: 120,
                              borderRadius: isBold ? 0 : 4,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    playlist.isAiGenerated ? Icons.auto_awesome : Icons.flash_on, 
                                    size: 10, 
                                    color: playlist.isAiGenerated ? BopTheme.green : Colors.orangeAccent
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    playlist.isAiGenerated ? 'AI' : 'Smart',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 120,
                      child: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${playlist.songs.length} songs',
                      style: const TextStyle(color: BopTheme.textSecondary, fontSize: 9),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        skipLoadingOnReload: true,
      ),
    );
  }
}
