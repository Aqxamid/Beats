// widgets/playlist_cover_widget.dart
// Spotify-style 2×2 album art collage for playlists.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';

class PlaylistCoverWidget extends StatelessWidget {
  final Playlist playlist;
  final double size;
  const PlaylistCoverWidget({
    super.key,
    required this.playlist,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<int>>>(
      future: _getArtwork(),
      builder: (context, snap) {
        final arts = snap.data ?? [];
        final color = Color(int.parse(playlist.coverColor.replaceFirst('#', '0xFF')));

        if (arts.isEmpty) {
          // No artwork — show colored placeholder with icon
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.queue_music,
                color: Colors.white.withAlpha(153), size: size * 0.45),
          );
        }

        if (arts.length == 1) {
          // Single artwork — show full size
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              Uint8List.fromList(arts[0]),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        }

        // 2×2 collage
        final half = size / 2;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: size,
            height: size,
            child: Column(
              children: [
                Row(
                  children: [
                    _tile(arts.length > 0 ? arts[0] : null, half, color),
                    _tile(arts.length > 1 ? arts[1] : null, half, color),
                  ],
                ),
                Row(
                  children: [
                    _tile(arts.length > 2 ? arts[2] : null, half, color),
                    _tile(arts.length > 3 ? arts[3] : null, half, color),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(List<int>? artBytes, double tileSize, Color fallback) {
    if (artBytes != null && artBytes.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(artBytes),
        width: tileSize,
        height: tileSize,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return Container(
      width: tileSize,
      height: tileSize,
      color: fallback.withAlpha(178), // ~0.7 opacity
    );
  }

  Future<List<List<int>>> _getArtwork() async {
    if (!playlist.songs.isLoaded) {
      await playlist.songs.load();
    }
    final songs = playlist.songs.toList();
    final arts = <List<int>>[];
    final seenArt = <int>{};
    for (final song in songs) {
      if (song.artBytes != null && song.artBytes!.isNotEmpty) {
        // Use hashCode to avoid duplicate identical arts
        final hash = song.artBytes!.length;
        if (!seenArt.contains(hash)) {
          seenArt.add(hash);
          arts.add(song.artBytes!);
        }
        if (arts.length >= 4) break;
      }
    }
    return arts;
  }
}
