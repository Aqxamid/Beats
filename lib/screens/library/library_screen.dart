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
import '../../widgets/playlist_cover_widget.dart';
import '../player/now_playing_screen.dart';
import 'album_screen.dart';
import 'playlist_screen.dart';
import './liked_songs_screen.dart';
import './metadata_editor_screen.dart';

// Filter state
enum LibraryFilter { all, playlists, artists, albums }
final libraryFilterProvider = StateProvider<LibraryFilter>((ref) => LibraryFilter.all);
final librarySelectionProvider = StateProvider<Set<int>>((ref) => {});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);
    final allSongs = ref.watch(allSongsProvider);
    final selection = ref.watch(librarySelectionProvider);
    final filter = ref.watch(libraryFilterProvider);
    final inSelectionMode = selection.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // ── Header + selection actions ──────
                      if (inSelectionMode)
                        _SelectionHeader(
                          count: selection.length,
                          onClear: () => ref.read(librarySelectionProvider.notifier).state = {},
                          onDelete: () async {
                            final confirm = await _showBulkRemoveDialog(context, selection.length);
                            if (confirm == true) {
                              final ids = selection.toList();
                              for (final id in ids) {
                                await DbService.instance.hideSong(id);
                                ref.read(playerProvider.notifier).removeSong(id);
                              }
                              ref.read(librarySelectionProvider.notifier).state = {};
                              ref.invalidate(allSongsProvider);
                              ref.invalidate(likedSongsProvider);
                              ref.invalidate(recentSongsProvider);
                            }
                          },
                        )
                      else
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
                                await ScannerService.instance.scanAndSave();
                                ref.invalidate(allSongsProvider);
                                ref.invalidate(recentSongsProvider);
                                ref.invalidate(likedSongsProvider);
                              },
                            ),
                          ],
                        ),

                      // ── Filter chips ──────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FilterChip(
                              'All Songs',
                              filter == LibraryFilter.all,
                              () {
                                ref.read(libraryFilterProvider.notifier).state = LibraryFilter.all;
                                ref.read(librarySelectionProvider.notifier).state = {};
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              'Playlists',
                              filter == LibraryFilter.playlists,
                              () {
                                ref.read(libraryFilterProvider.notifier).state = LibraryFilter.playlists;
                                ref.read(librarySelectionProvider.notifier).state = {};
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              'Artists',
                              filter == LibraryFilter.artists,
                              () {
                                ref.read(libraryFilterProvider.notifier).state = LibraryFilter.artists;
                                ref.read(librarySelectionProvider.notifier).state = {};
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              'Albums',
                              filter == LibraryFilter.albums,
                              () {
                                ref.read(libraryFilterProvider.notifier).state = LibraryFilter.albums;
                                ref.read(librarySelectionProvider.notifier).state = {};
                              },
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
                              ref.read(playerProvider.notifier).playQueue(songs);
                            }
                          },
                        ),
                        loading: () => _LikedSongsTile(count: 0, onTap: () {}),
                        error: (_, __) => _LikedSongsTile(count: 0, onTap: () {}),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),

              // ── All Songs / Playlists list (lazy) ──────────
              if (filter == LibraryFilter.playlists)
                ref.watch(playlistsStreamProvider).when(
                  data: (list) => SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return ListTile(
                          leading: PlaylistCoverWidget(playlist: p, size: 48),
                          title: Text(p.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('${p.songs.length} songs',
                              style: const TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 12)),
                          onTap: () => showPlaylistDetails(context, ref, p),
                          onLongPress: () => _confirmDeletePlaylist(context, ref, p),
                        );
                      },
                    ),
                  ),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: Text('Error loading playlists', style: TextStyle(color: Colors.red)),
                  ),
                )
              else
                allSongs.when(
                  data: (songs) {
                    var filteredSongs = songs;
                    if (filter == LibraryFilter.artists) {
                      filteredSongs = List<Song>.from(songs)..sort((a, b) => a.artist.compareTo(b.artist));
                    } else if (filter == LibraryFilter.albums) {
                      filteredSongs = List<Song>.from(songs)..sort((a, b) => a.album.compareTo(b.album));
                    }

                    if (filteredSongs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No songs found.\nScan your device from the home screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: BeatSpillTheme.textMuted),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (_, i) {
                          final song = filteredSongs[i];
                          final isSelected = selection.contains(song.id);
                          return _SongTile(
                            song: song,
                            isSelected: isSelected,
                            inSelectionMode: inSelectionMode,
                            onTap: () {
                              if (inSelectionMode) {
                                final newSet = Set<int>.from(selection);
                                if (isSelected) {
                                  newSet.remove(song.id);
                                } else {
                                  newSet.add(song.id);
                                }
                                ref.read(librarySelectionProvider.notifier).state = newSet;
                              } else {
                                ref.read(playerProvider.notifier).playQueue(
                                  filteredSongs,
                                  startIndex: i,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NowPlayingScreen(song: song),
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              if (!inSelectionMode) {
                                ref.read(librarySelectionProvider.notifier).state = {song.id};
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: Text('Error loading library'),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
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
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool inSelectionMode;

  const _SongTile({
    required this.song,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.inSelectionMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? BeatSpillTheme.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        onTap: onTap,
        onLongPress: onLongPress,
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
      trailing: inSelectionMode
          ? Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? BeatSpillTheme.green : BeatSpillTheme.textSecondary,
              size: 20,
            )
          : Row(
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
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  const _SelectionHeader({
    required this.count,
    required this.onClear,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClear,
          ),
          const SizedBox(width: 8),
          Text('$count selected',
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: BeatSpillTheme.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

Future<bool?> _showBulkRemoveDialog(BuildContext context, int count) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF282828),
      title: Text('Remove $count Songs?', style: const TextStyle(color: Colors.white)),
      content: const Text(
          'Remove selected songs from your library? The files will not be deleted from your device.',
          style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: BeatSpillTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Remove', style: TextStyle(color: BeatSpillTheme.red)),
        ),
      ],
    ),
  );
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
            leading: const Icon(Icons.album_outlined, color: BeatSpillTheme.textSecondary, size: 20),
            title: const Text('View album', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumScreen(albumName: song.album, artist: song.artist),
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
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: BeatSpillTheme.red, size: 20),
            title: const Text('Remove from library', style: TextStyle(color: BeatSpillTheme.red, fontSize: 14)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF282828),
                  title: const Text('Remove Song', style: TextStyle(color: Colors.white)),
                  content: Text('Remove "${song.title}" from your library? The file will not be deleted from your device.',
                      style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel', style: TextStyle(color: BeatSpillTheme.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Remove', style: TextStyle(color: BeatSpillTheme.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await DbService.instance.hideSong(song.id);
                if (context.mounted) {
                  ref.read(playerProvider.notifier).removeSong(song.id);
                  ref.invalidate(allSongsProvider);
                  ref.invalidate(likedSongsProvider);
                  ref.invalidate(recentSongsProvider);
                }
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
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

void showPlaylistDetails(BuildContext context, WidgetRef ref, Playlist playlist) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlaylistScreen(playlist: playlist),
    ),
  );
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
