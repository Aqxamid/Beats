// screens/library/library_screen.dart
import 'dart:io';
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
import 'artist_screen.dart';
import 'playlist_screen.dart';
import './liked_songs_screen.dart';
import './metadata_editor_screen.dart';
import '../../services/metadata_service.dart';

// Filter state
enum LibraryFilter { all, playlists, artists, albums }
final libraryFilterProvider = StateProvider<LibraryFilter>((ref) => LibraryFilter.all);
final librarySelectionProvider = StateProvider<Set<int>>((ref) => {});
final libraryPlaylistSelectionProvider = StateProvider<Set<int>>((ref) => {});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);
    final allSongs = ref.watch(allSongsProvider);
    final selection = ref.watch(librarySelectionProvider);
    final playlistSelection = ref.watch(libraryPlaylistSelectionProvider);
    final filter = ref.watch(libraryFilterProvider);
    final inSelectionMode = selection.isNotEmpty;
    final inPlaylistSelectionMode = playlistSelection.isNotEmpty;

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
                      if (inSelectionMode && filter != LibraryFilter.playlists)
                        _SelectionHeader(
                          count: selection.length,
                          onClear: () => ref.read(librarySelectionProvider.notifier).state = {},
                          onAutoFill: () => _showBulkAutoFillDialog(context, ref, selection.toList()),
                          onAddToPlaylist: () => _showMultiPlaylistSelector(context, ref, selection.toList()),
                          onDelete: () async {
                            final confirm = await _showBulkRemoveDialog(context, selection.length);
                            if (confirm == true) {
                              final ids = selection.toList();
                              for (final id in ids) {
                                final s = await DbService.instance.songs.get(id);
                                if (s != null) {
                                  try {
                                    final f = File(s.filePath);
                                    if (f.existsSync()) f.deleteSync();
                                  } catch (_) {}
                                }
                                await DbService.instance.deleteSong(id);
                                ref.read(playerProvider.notifier).removeSong(id);
                              }
                              ref.read(librarySelectionProvider.notifier).state = {};
                              ref.invalidate(allSongsProvider);
                              ref.invalidate(likedSongsProvider);
                              ref.invalidate(recentSongsProvider);
                            }
                          },
                        )
                      else if (inPlaylistSelectionMode && filter == LibraryFilter.playlists)
                        _SelectionHeader(
                          count: playlistSelection.length,
                          onClear: () => ref.read(libraryPlaylistSelectionProvider.notifier).state = {},
                          onDelete: () async {
                            final confirm = await _showBulkRemoveDialog(context, playlistSelection.length, isPlaylist: true);
                            if (confirm == true) {
                              for (final id in playlistSelection) {
                                await DbService.instance.deletePlaylist(id);
                              }
                              ref.read(libraryPlaylistSelectionProvider.notifier).state = {};
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add, color: BopTheme.textSecondary),
                                  tooltip: 'Create Playlist',
                                  onPressed: () => _showCreatePlaylistDialog(context),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, color: BopTheme.textSecondary),
                                  tooltip: 'Rescan Device',
                                  onPressed: () => _showRescanDialog(context, ref),
                                ),
                              ],
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: playlistSelection.contains(p.id) ? BopTheme.green.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: PlaylistCoverWidget(playlist: p, size: 48),
                              title: Text(p.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text('${p.songs.length} songs',
                                  style: const TextStyle(color: BopTheme.textSecondary, fontSize: 12)),
                              trailing: inPlaylistSelectionMode
                                  ? Icon(
                                      playlistSelection.contains(p.id) ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: playlistSelection.contains(p.id) ? BopTheme.green : BopTheme.textSecondary,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                if (inPlaylistSelectionMode) {
                                  final newSet = Set<int>.from(playlistSelection);
                                  if (newSet.contains(p.id)) {
                                    newSet.remove(p.id);
                                  } else {
                                    newSet.add(p.id);
                                  }
                                  ref.read(libraryPlaylistSelectionProvider.notifier).state = newSet;
                                } else {
                                  showPlaylistDetails(context, ref, p);
                                }
                              },
                              onLongPress: () {
                                if (!inPlaylistSelectionMode) {
                                  ref.read(libraryPlaylistSelectionProvider.notifier).state = {p.id};
                                }
                              },
                            ),
                          ),
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
                    if (songs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No songs found.\nScan your device from the home screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: BopTheme.textMuted),
                            ),
                          ),
                        ),
                      );
                    }

                    if (filter == LibraryFilter.artists) {
                      final artistMapping = <String, List<Song>>{};
                      for (final s in songs) {
                        artistMapping.putIfAbsent(s.artist, () => []).add(s);
                      }
                      final artistsList = artistMapping.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key));
                        
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.builder(
                          itemCount: artistsList.length,
                          itemBuilder: (_, i) {
                            final artist = artistsList[i].key;
                            final artistSongs = artistsList[i].value;
                            final artSong = artistSongs.cast<Song?>().firstWhere(
                              (s) => s!.artBytes != null && s.artBytes!.isNotEmpty,
                              orElse: () => null,
                            );
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: BopTheme.surfaceAlt,
                                    image: artSong?.artBytes != null && artSong!.artBytes!.isNotEmpty
                                      ? DecorationImage(
                                          image: ResizeImage(MemoryImage(Uint8List.fromList(artSong.artBytes!)), width: 100, height: 100), 
                                          fit: BoxFit.cover
                                        )
                                      : null,
                                  ),
                                  child: artSong?.artBytes == null || artSong!.artBytes!.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white54)
                                    : null,
                                ),
                                title: Text(artist, style: const TextStyle(color: Colors.white)),
                                subtitle: Text('${artistSongs.length} songs', style: const TextStyle(color: BopTheme.textSecondary, fontSize: 12)),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistScreen(artistName: artist)));
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }

                    if (filter == LibraryFilter.albums) {
                      final albumMapping = <String, List<Song>>{};
                      for (final s in songs) {
                        albumMapping.putIfAbsent(s.album, () => []).add(s);
                      }
                      final albumsList = albumMapping.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key));
                        
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.builder(
                          itemCount: albumsList.length,
                          itemBuilder: (_, i) {
                            final album = albumsList[i].key;
                            final albumSongs = albumsList[i].value;
                            final artist = albumSongs.first.artist;
                            final artSong = albumSongs.cast<Song?>().firstWhere(
                              (s) => s!.artBytes != null && s.artBytes!.isNotEmpty,
                              orElse: () => null,
                            );
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: BopTheme.surfaceAlt,
                                    image: artSong?.artBytes != null && artSong!.artBytes!.isNotEmpty
                                      ? DecorationImage(
                                          image: ResizeImage(MemoryImage(Uint8List.fromList(artSong.artBytes!)), width: 100, height: 100), 
                                          fit: BoxFit.cover
                                        )
                                      : null,
                                  ),
                                  child: artSong?.artBytes == null || artSong!.artBytes!.isEmpty
                                    ? const Icon(Icons.album, color: Colors.white54)
                                    : null,
                                ),
                                title: Text(album, style: const TextStyle(color: Colors.white)),
                                subtitle: Text(artist, style: const TextStyle(color: BopTheme.textSecondary, fontSize: 12)),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumScreen(albumName: album, artist: artist)));
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }

                    final filteredSongs = songs;

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (_, i) {
                          final song = filteredSongs[i];
                          final isSelected = selection.contains(song.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SongTile(
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
                            ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? BopTheme.green : BopTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.black : BopTheme.textSecondary,
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
            colors: [Color(0xFF4A0070), BopTheme.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 20),
      ),
      title: const Text('Liked Songs',
          style: TextStyle(
              color: BopTheme.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text('$count songs',
          style: const TextStyle(color: BopTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right,
          color: BopTheme.textSecondary),
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
        color: isSelected ? BopTheme.green.withOpacity(0.1) : Colors.transparent,
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
                  cacheWidth: 88,
                  cacheHeight: 88,
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
              color: BopTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist,
          style: const TextStyle(
              color: BopTheme.textSecondary, fontSize: 11)),
      trailing: inSelectionMode
          ? Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? BopTheme.green : BopTheme.textSecondary,
              size: 20,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(song.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: song.isLiked
                          ? BopTheme.green
                          : BopTheme.textSecondary,
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
                      color: BopTheme.textSecondary, size: 20),
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
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onAutoFill;

  const _SelectionHeader({
    required this.count,
    required this.onClear,
    required this.onDelete,
    this.onAddToPlaylist,
    this.onAutoFill,
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
          if (onAutoFill != null)
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: BopTheme.green),
              tooltip: 'Auto-fill Metadata',
              onPressed: onAutoFill,
            ),
          if (onAddToPlaylist != null)
            IconButton(
              icon: const Icon(Icons.playlist_add, color: Colors.white),
              tooltip: 'Add to Playlist',
              onPressed: onAddToPlaylist,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: BopTheme.red),
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

Future<bool?> _showBulkRemoveDialog(BuildContext context, int count, {bool isPlaylist = false}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF282828),
      title: Text('Remove $count ${isPlaylist ? 'Playlists' : 'Songs'}?', style: const TextStyle(color: Colors.white)),
      content: Text(
          isPlaylist 
              ? 'This will permanently delete the selected playlists from your library.'
              : 'This will permanently delete the selected files from your device and library.',
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
}

Future<void> _showBulkAutoFillDialog(BuildContext context, WidgetRef ref, List<int> songIds) async {
  final List<Song> selectedSongs = [];
  for (final id in songIds) {
    final s = await DbService.instance.songs.get(id);
    if (s != null) selectedSongs.add(s);
  }

  if (context.mounted && selectedSongs.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetadataEditorScreen(songs: selectedSongs),
      ),
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
                            cacheWidth: 88,
                            cacheHeight: 88,
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
                              color: BopTheme.textSecondary,
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
                color: song.isLiked ? BopTheme.green : BopTheme.textSecondary,
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
            leading: const Icon(Icons.playlist_add, color: BopTheme.textSecondary, size: 20),
            title: const Text('Add to playlist', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              _showPlaylistSelector(context, ref, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music, color: BopTheme.textSecondary, size: 20),
            title: const Text('Add to queue', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              ref.read(playerProvider.notifier).addToQueue(song);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to queue')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: BopTheme.textSecondary, size: 20),
            title: const Text('Share', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Share.share('Check out this song: ${song.title} by ${song.artist}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: BopTheme.textSecondary, size: 20),
            title: const Text('Edit info', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MetadataEditorScreen(songs: [song]),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.album_outlined, color: BopTheme.textSecondary, size: 20),
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
            leading: const Icon(Icons.info_outline, color: BopTheme.textSecondary, size: 20),
            title: const Text('Song credits', style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              _showCreditsDialog(context, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: BopTheme.red, size: 20),
            title: const Text('Remove from library', style: TextStyle(color: BopTheme.red, fontSize: 14)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF282828),
                  title: const Text('Delete Song', style: TextStyle(color: Colors.white)),
                  content: Text('Permanently delete "${song.title}" from your device and library?',
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
                try {
                  final f = File(song.filePath);
                  if (f.existsSync()) f.deleteSync();
                } catch (_) {}
                await DbService.instance.deleteSong(song.id);
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

void _showMultiPlaylistSelector(BuildContext context, WidgetRef ref, List<int> songIds) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF282828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final asyncPlaylists = ref.watch(playlistsStreamProvider);
        return asyncPlaylists.when(
          data: (playlists) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No playlists yet.', style: TextStyle(color: BopTheme.textSecondary)),
                    )
                  else
                    ...playlists.map((p) => ListTile(
                          leading: const Icon(Icons.queue_music, color: Colors.white54),
                          title: Text(p.name, style: const TextStyle(color: Colors.white)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            for (final id in songIds) {
                              await DbService.instance.addSongToPlaylist(p.id, id);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${songIds.length} songs to ${p.name}', style: const TextStyle(color: Colors.white)), backgroundColor: BopTheme.surfaceAlt));
                            }
                            ref.read(librarySelectionProvider.notifier).state = {};
                          },
                        )),
                ],
              ),
            );
          },
          loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox(),
        );
      },
    ),
  );
}

void _showCreatePlaylistDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF282828),
      title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Playlist name',
          hintStyle: TextStyle(color: Colors.white38),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: BopTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              await DbService.instance.createPlaylist(name);
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
          child: const Text('Create', style: TextStyle(color: BopTheme.green)),
        ),
      ],
    ),
  );
}

void _showRescanDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool started = false;
      int current = 0;
      int total = 0;
      bool done = false;

      return StatefulBuilder(builder: (context, setDialogState) {
        if (!started) {
          started = true;
          ScannerService.instance.scanAndSave(
            onProgress: (c, t) {
              if (ctx.mounted) {
                setDialogState(() {
                  current = c;
                  total = t;
                  if (t > 0 && c >= t) done = true;
                });
              }
            },
          ).then((_) {
            if (ctx.mounted) {
              setDialogState(() => done = true);
              ref.invalidate(allSongsProvider);
              ref.invalidate(recentSongsProvider);
              ref.invalidate(likedSongsProvider);
            }
          });
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('Scanning Library', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (total > 0) ...[
                LinearProgressIndicator(
                  value: total == 0 ? 0 : current / total,
                  backgroundColor: Colors.white24,
                  color: BopTheme.green,
                ),
                const SizedBox(height: 16),
                Text('$current / $total scanned', style: const TextStyle(color: Colors.white70)),
              ] else if (done) ...[
                const Text('Library is up to date!', style: TextStyle(color: Colors.white70)),
              ] else ...[
                const CircularProgressIndicator(color: BopTheme.green),
                const SizedBox(height: 16),
                const Text('Looking for new files...', style: TextStyle(color: Colors.white70)),
              ],
            ],
          ),
          actions: [
            if (done || total == 0)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: BopTheme.green)),
              ),
          ],
        );
      });
    },
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
          child: const Text('Cancel', style: TextStyle(color: BopTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await DbService.instance.deletePlaylist(playlist.id);
            // The stream provider will auto-update
          },
          child: const Text('Delete', style: TextStyle(color: BopTheme.red)),
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
