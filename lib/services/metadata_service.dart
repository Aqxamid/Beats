import 'dart:convert';
import 'dart:io';
import '../models/song.dart';
import 'db_service.dart';

class MetadataService {
  MetadataService._();
  static final MetadataService instance = MetadataService._();

  /// Fetches metadata from MusicBrainz API for a given song.
  Future<bool> fetchAndFillMetadata(Song song) async {
    if (song.isHidden) return false;
    final hasArtist = !isArtistMissing(song.artist);
    final hasAlbum = !isAlbumMissing(song.album);
    final hasGenre = !isGenreMissing(song.genre);
    
    // If we have all major tags, don't overwrite
    if (hasArtist && hasAlbum && hasGenre) return false;

    final isArtistM = !hasArtist;
    final isAlbumM = !hasAlbum;
    final isGenreM = !hasGenre;

    // Build search query with 4-point verification
    String queryStr = 'recording:"${song.title}"';
    if (!isArtistM) queryStr += ' AND artist:"${song.artist}"';
    if (!isAlbumM) queryStr += ' AND release:"${song.album}"';
    
    final query = Uri.encodeComponent(queryStr);
    final url = Uri.parse('https://musicbrainz.org/ws/2/recording/?query=$query&fmt=json');
    
    // Try primary fetch
    bool success = await _tryFetch(song, url, isArtistM, isAlbumM, isGenreM);
    if (success) return true;

    // Looser fallback: Just title and artist (if available)
    if (!isArtistM) {
      final looseQuery = Uri.encodeComponent('recording:"${song.title}" AND artist:"${song.artist}"');
      final looseUrl = Uri.parse('https://musicbrainz.org/ws/2/recording/?query=$looseQuery&fmt=json');
      success = await _tryFetch(song, looseUrl, isArtistM, isAlbumM, isGenreM);
    }
    
    return success;
  }

  Future<bool> _tryFetch(Song song, Uri url, bool isArtistMissing, bool isAlbumMissing, bool isGenreMissing) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'BopMusicPlayer/2.0.0 ( contact@bop.com )');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        
        if (data['recordings'] != null) {
          final recordings = data['recordings'] as List;
          if (recordings.isNotEmpty) {
            final bestMatch = recordings.first;
            bool updated = false;

            if (isArtistMissing && bestMatch['artist-credit'] != null) {
              final artists = bestMatch['artist-credit'] as List;
              if (artists.isNotEmpty && artists.first['name'] != null) {
                song.artist = artists.first['name'];
                updated = true;
              }
            }

            if (isAlbumMissing && bestMatch['releases'] != null) {
              final releases = bestMatch['releases'] as List;
              if (releases.isNotEmpty && releases.first['title'] != null) {
                song.album = releases.first['title'];
                updated = true;
              }
            }

            if (isGenreMissing && bestMatch['tags'] != null) {
              final tags = bestMatch['tags'] as List;
              if (tags.isNotEmpty) {
                final genreCandidate = tags.map((t) => t['name'].toString()).firstWhere(
                  (name) => name != 'rock' && name != 'pop' || tags.length == 1, 
                  orElse: () => tags.first['name'].toString()
                );
                song.genre = _capitalize(genreCandidate);
                updated = true;
              }
            }

            if (updated) {
              await DbService.instance.isar.writeTxn(() async {
                await DbService.instance.songs.put(song);
              });
            }
            return updated;
          }
        }
      }
    } catch (e) {
      print('[Metadata] Fetch error: $e');
    }
    return false;
  }

  bool isArtistMissing(String? artist) {
    if (artist == null || artist.isEmpty) return true;
    final a = artist.toLowerCase().trim();
    return a == 'unknown artist' || a == '<unknown>' || a == 'unknown';
  }

  bool isAlbumMissing(String? album) {
    if (album == null || album.isEmpty) return true;
    final a = album.toLowerCase().trim();
    return a == 'unknown album' || a == '<unknown>' || a == 'unknown';
  }

  bool isGenreMissing(String? genre) {
    if (genre == null || genre.isEmpty) return true;
    final g = genre.toLowerCase().trim();
    return g == 'unknown' || g == '<unknown>' || g == 'other' || g == 'unknown genre';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
