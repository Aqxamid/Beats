import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';

class PlaylistCollage extends StatelessWidget {
  final List<Song> songs;
  final double size;
  final double borderRadius;

  const PlaylistCollage({
    super.key,
    required this.songs,
    this.size = 80,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: BopTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(
          child: Icon(Icons.music_note, color: Colors.white10, size: 32),
        ),
      );
    }

    final displaySongs = songs.take(4).toList();
    
    // If only 1-3 songs, or if we want a single cover, just show the first art
    if (displaySongs.length < 4) {
      final s = displaySongs.first;
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          color: BopTheme.surfaceAlt,
          child: s.artBytes != null && s.artBytes!.isNotEmpty
              ? Image.memory(
                  Uint8List.fromList(s.artBytes!),
                  key: ValueKey('collage_single_${s.id}'),
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  gaplessPlayback: true,
                  cacheWidth: (size * 2).toInt(),
                  cacheHeight: (size * 2).toInt(),
                )
              : const Center(
                  child: Icon(Icons.music_note, color: Colors.white10, size: 32),
                ),
        ),
      );
    }

    // 2x2 Grid Collage
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: GridView.count(
          crossAxisCount: 2,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: displaySongs.map((s) {
            return s.artBytes != null && s.artBytes!.isNotEmpty
                ? Image.memory(
                    Uint8List.fromList(s.artBytes!),
                    key: ValueKey('collage_grid_${s.id}'),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: size.toInt(),
                    cacheHeight: size.toInt(),
                  )
                : Container(
                    color: Colors.white12,
                    child: const Icon(Icons.music_note, color: Colors.white10, size: 16),
                  );
          }).toList(),
        ),
      ),
    );
  }
}
