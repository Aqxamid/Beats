// screens/library/library_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mini_player.dart';
import '../../providers/stats_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/scanner_service.dart';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/db_service.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../widgets/song_option_widgets.dart';
import '../player/now_playing_screen.dart';
import './liked_songs_screen.dart';
import './metadata_editor_screen.dart';

// Filter state
enum LibraryFilter { all, playlists, artists, albums }
final libraryFilterProvider = StateProvider<LibraryFilter>((ref) => LibraryFilter.all);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);
    final allSongs = ref.watch(allSongsProvider);
    final filter = ref.watch(libraryFilterProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            children: [
              const SizedBox(height: 16),
                  // ── Header + new playlist button ──────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your Library',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 20)),
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: BeatSpillTheme.textSecondary),
                        tooltip: 'Rescan Device',
                        onPressed: () async {
                          // Rescan for new files added after initial setup
                          await ScannerService.instance.scanAndSave();
                          ref.invalidate(allSongsProvider);
                        },
                      ),
                    ],
                  ),

                  // ── Filter chips ──────────────────────
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          'All Songs',
                          filter == LibraryFilter.all,
                          () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.all,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          'Playlists',
                          filter == LibraryFilter.playlists,
                          () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.playlists,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          'Artists',
                          filter == LibraryFilter.artists,
                          () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.artists,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          'Albums',
                          filter == LibraryFilter.albums,
                          () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.albums,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Liked Songs shortcut ──────────────
                  likedSongs.when(
                    data: (songs) => _LikedSongsTile(
                      count: songs.length,
                      onTap: () {
                        if (songs.isNotEmpty) {
                          ref
                              .read(playerProvider.notifier)
                              .playQueue(songs);
                        }
                      },
                    ),
                    loading: () => _LikedSongsTile(count: 0, onTap: () {}),
                    error: (_, __) => _LikedSongsTile(count: 0, onTap: () {}),
                  ),
                  const Divider(height: 1),

                  // ── All Songs / Playlists list ──────────
                  if (filter == LibraryFilter.playlists)
                    ref.watch(playlistsStreamProvider).when(
                      data: (list) => Column(
                        children: list.map((Playlist p) {
                          final firstSong = p.songs.firstOrNull;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: Color(int.parse(p.coverColor.replaceFirst('#', '0xFF'))),
                                child: firstSong?.artBytes != null && firstSong!.artBytes!.isNotEmpty
                                    ? Image.memory(
                                        Uint8List.fromList(firstSong!.artBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.playlist_play, color: Colors.white),
                              ),
                            ),
                            title: Text(p.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${p.songs.length} songs',
                                style: const TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 12)),
                            onTap: () => _showPlaylistDetails(context, ref, p),
                            onLongPress: () => _confirmDeletePlaylist(context, ref, p),
                          );
                        }).toList(),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error loading playlists', style: TextStyle(color: Colors.red)),
                    )
                  else
                    allSongs.when(
                      data: (songs) {
                        var filteredSongs = songs;
                        if (filter == LibraryFilter.artists) {
                        // Just sorting by artist for now to show "Artists" filter works
                        filteredSongs = List.from(songs)..sort((a, b) => a.artist.compareTo(b.artist));
                      } else if (filter == LibraryFilter.albums) {
                        filteredSongs = List.from(songs)..sort((a, b) => a.album.compareTo(b.album));
                      }

                      if (filteredSongs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No songs found.\nScan your device from the home screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: BeatSpillTheme.textMuted),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: filteredSongs.asMap().entries.map((entry) {
                          final song = entry.value;
                          return _SongTile(
                            song: song,
                            onTap: () {
                              ref
                                  .read(playerProvider.notifier)
                                  .playQueue(filteredSongs, startIndex: entry.key);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NowPlayingScreen(song: song),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )),
                    error: (_, __) => const Text('Error loading library'),
                  ),

                  const SizedBox(height: 100), // Space to scroll past miniplayer
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? BeatSpillTheme.green : BeatSpillTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.black : BeatSpillTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
    );
  }
}

class _LikedSongsTile extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _LikedSongsTile({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A0070), BeatSpillTheme.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 20),
      ),
      title: const Text('Liked Songs',
          style: TextStyle(
              color: BeatSpillTheme.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text('$count songs',
          style: const TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right,
          color: BeatSpillTheme.textSecondary),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
        );
      },
    );
  }
}

class _SongTile extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;
  const _SongTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 44,
          height: 44,
          child: song.artBytes != null && song.artBytes!.isNotEmpty
              ? Image.memory(
                  Uint8List.fromList(song.artBytes!),
                  key: ValueKey('lib_art_${song.id}'),
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
      title: Text(song.title,
          style: const TextStyle(
              color: BeatSpillTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist,
          style: const TextStyle(
              color: BeatSpillTheme.textSecondary, fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(song.isLiked ? Icons.favorite : Icons.favorite_border,
                color: song.isLiked
                    ? BeatSpillTheme.green
                    : BeatSpillTheme.textSecondary,
                size: 20),
            onPressed: () async {
              await DbService.instance.toggleLike(song.id);
              ref.invalidate(likedSongsProvider);
              ref.invalidate(allSongsProvider);
              ref.read(playerProvider.notifier).refreshCurrentSong();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: BeatSpillTheme.textSecondary, size: 20),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: const Color(0xFF282828),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => _LibrarySongMenu(song: song),
              );
            },
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _LibrarySongMenu extends ConsumerWidget {
  final Song song;
  const _LibrarySongMenu({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    child: song.artBytes != null
                        ? Image.memory(
                            Uint8List.fromList(song.artBytes!),
                            fit: BoxFit.cover,
                          )
                        : const ColoredBox(color: Color(0xFFC0392B)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(song.artist,
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
          ListTile(
            leading: Icon(
                song.isLiked ? Icons.favorite : Icons.favorite_border,
                color: song.isLiked ? BeatSpillTheme.green : BeatSpillTheme.textSecondary,
                size: 20),
            title: Text(song.isLiked ? 'Unlike' : 'Like',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () async {
              Navigator.pop(context);
              await DbService.instance.toggleLike(song.id);
              ref.invalidate(likedSongsProvider);
              ref.invalidate(allSongsProvider);
              ref.read(playerProvider.notifier).refreshCurrentSong();
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: BeatSpillTheme.textSecondary, size: 20),
            title: const Text('Add to playlist', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              _showPlaylistSelector(context, ref, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music, color: BeatSpillTheme.textSecondary, size: 20),
            title: const Text('Add to queue', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              ref.read(playerProvider.notifier).addToQueue(song);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to queue')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: BeatSpillTheme.textSecondary, size: 20),
            title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Share.share('Check out this song: ${song.title} by ${song.artist}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: BeatSpillTheme.textSecondary, size: 20),
            title: const Text('Edit info', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MetadataEditorScreen(song: song),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: BeatSpillTheme.textSecondary, size: 20),
            title: const Text('Song credits', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              _showCreditsDialog(context, song);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
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

void _showPlaylistDetails(BuildContext context, WidgetRef ref, Playlist playlist) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _PlaylistDetailSheet(playlist: playlist),
  );
}

class _PlaylistDetailSheet extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistDetailSheet({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all songs to ensure this sheet rebuilds when a song's liked status changes
    ref.watch(allSongsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playlist.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${playlist.songs.length} songs',
                          style: const TextStyle(color: BeatSpillTheme.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: BeatSpillTheme.red),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeletePlaylist(context, ref, playlist);
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          Expanded(
            child: ListView(
              children: playlist.songs
                  .map((s) => _SongTile(
                        song: s,
                        onTap: () {
                          ref.read(playerProvider.notifier).playQueue(
                              playlist.songs.toList(),
                              startIndex: playlist.songs.toList().indexOf(s));
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => NowPlayingScreen(song: s)));
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmDeletePlaylist(BuildContext context, WidgetRef ref, Playlist playlist) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF282828),
      title: const Text('Delete Playlist?', style: TextStyle(color: Colors.white)),
      content: Text('Are you sure you want to delete "${playlist.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: BeatSpillTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await DbService.instance.deletePlaylist(playlist.id);
            // The stream provider will auto-update
          },
          child: const Text('Delete', style: TextStyle(color: BeatSpillTheme.red)),
        ),
      ],
    ),
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
