// services/llm_service.dart
// Local on-device text generator for Wrapped recaps.
// Attempts to use fllama (TinyLlama GGUF) if a model file exists on-device.
// Falls back to smart template-based generation (no external API calls).
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/song.dart';
import '../models/wrapped_report.dart';
import 'db_service.dart';
import 'lyrics_service.dart';

class SmartPlaylistData {
  final String name;
  final List<Song> songs;
  final bool isAiGenerated;
  SmartPlaylistData({required this.name, required this.songs, this.isAiGenerated = false});
}

class LlmService {
  LlmService._();
  static final LlmService instance = LlmService._();

  static const _apiKeyPref = 'llm_api_key';
  static const _modelPathPref = 'llm_model_path';

  String _cachedApiKey = '';
  String _modelPath = '';
  bool _modelAvailable = false;
  Llama? _llama;
  
  // Caching
  List<SmartPlaylistData>? _cachedPlaylists;
  DateTime? _lastPlaylistUpdate;

  /// Get current API key (for settings screen compatibility)
  Future<String> get currentApiKey async {
    if (_cachedApiKey.isNotEmpty) return _cachedApiKey;
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = prefs.getString(_apiKeyPref) ?? '';
    return _cachedApiKey;
  }

  /// Update API key
  Future<void> updateApiKey(String key) async {
    _cachedApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  /// Get current model path
  Future<String> get currentModelPath async {
    if (_modelPath.isNotEmpty) return _modelPath;
    final prefs = await SharedPreferences.getInstance();
    _modelPath = prefs.getString(_modelPathPref) ?? '';
    return _modelPath;
  }

  /// Update model path and check availability
  Future<void> updateModelPath(String path) async {
    _modelPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPathPref, path);
    _modelAvailable = path.isNotEmpty && await File(path).exists();
  }

  /// Load or switch the model
  Future<void> loadModel([String? modelPath]) async {
    final path = modelPath ?? await currentModelPath;
    if (path.isEmpty) return;

    File modelFile = File(path);
    if (!await modelFile.exists()) {
      _modelAvailable = false;
      return;
    }

    // Android specific: FilePicker often returns content URIs or temporary paths.
    // Native LLM libraries (llama_cpp) need a direct, persistent file path.
    // We copy the file to the app's internal documents directory.
    if (path.contains('/cache/') || path.contains('/com.android.providers')) {
       try {
         print('[LLM] Copying model to internal storage for persistence...');
         final docDir = await getApplicationDocumentsDirectory();
         final newPath = '${docDir.path}/model.gguf';
         final newFile = File(newPath);
         
         if (await newFile.exists()) await newFile.delete();
         await modelFile.copy(newPath);
         
         modelFile = newFile;
         await updateModelPath(newPath);
         print('[LLM] Model copied to: $newPath');
       } catch (e) {
         print('[LLM] Failed to copy model: $e');
         throw Exception('Failed to copy model to internal storage: $e');
       }
    }

    // Dispose old model before loading new one to free RAM
    disposeModel();

    try {
      print('[LLM] Attempting to load model from: ${modelFile.path}');
      _llama = Llama(modelFile.path, ModelParams(), ContextParams());
      _modelAvailable = _llama != null;
      _modelPath = modelFile.path;
      print('[LLM] Model loaded successfully: $_modelAvailable');
    } catch (e) {
      final errorStr = e.toString();
      String userMessage = errorStr;
      
      if (errorStr.contains('libllama.so') || errorStr.contains('dlopen failed')) {
        // ... (existing architecture error handling)
        final arch = Platform.operatingSystemVersion.toLowerCase();
        userMessage = 'Native library (libllama.so) not compatible or missing. ';
        if (arch.contains('x86_64')) {
          userMessage += 'Emulators (x86_64) are often unsupported by GGUF libraries. Please use a physical ARM64 device.';
        } else {
          userMessage += 'Your device architecture might not be supported.';
        }
      }
      
      print('[LLM] Error loading model: $userMessage');
      _modelAvailable = false;
      throw Exception(userMessage);
    }
  }

  /// Explicitly free up RAM used by the GGUF model
  void disposeModel() {
    try {
      if (_llama != null) {
        print('[LLM] Disposing existing model...');
        _llama!.dispose(); // Correct method for llama_cpp_dart
        _llama = null;
        _modelAvailable = false;
      }
    } catch (e) {
      print('[LLM] Error disposing model: $e');
    }
  }

  /// Generate a Wrapped recap paragraph for [report].
  /// Tries the real model first, then Gemini API (if key exists), then falls back to templates.
  Future<String> generateWrappedRecap(WrappedReport report) async {
    // 1. Prioritize Cached Recap
    if (report.llmRecap.isNotEmpty) {
      print('[LLM] Using cached recap for ${report.periodLabel}');
      return report.llmRecap;
    }

    String? lyricsSnippet;
    try {
      final db = DbService.instance;
      final song = await db.songs.filter().titleEqualTo(report.topSong).isHiddenEqualTo(false).findFirst();
      if (song != null) {
        final lyrics = await LyricsService.instance.fetchLyrics(song);
        if (lyrics != null && lyrics.isNotEmpty) {
           lyricsSnippet = lyrics.replaceAll(RegExp(r'\[.*?\]'), ' ').trim();
           if (lyricsSnippet.length > 200) lyricsSnippet = lyricsSnippet.substring(0, 200);
        }
      }
    } catch (_) {}

    final prompt = _buildPrompt(report, lyricsSnippet);

    // 2. Try Local Model (GGUF)
    if (_modelAvailable && _llama != null) {
      try {
        print('[LLM] Generating via Local GGUF...');
        final fullPrompt = "<s>[INST] $prompt [/INST]";
        _llama!.setPrompt(fullPrompt);
        final response = await _llama!.generateCompleteText(maxTokens: 128);

        if (response.isNotEmpty) {
          return _saveAndReturnRecap(report, response.trim());
        }
      } catch (e) {
        print('[LLM] Local generation error: $e');
      }
    }

    // 3. Try Gemini API (if API Key provided)
    final apiKey = await currentApiKey;
    if (apiKey.isNotEmpty) {
      try {
        print('[LLM] Generating via Gemini API...');
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [{
              'parts': [{'text': prompt}]
            }],
            'generationConfig': {
              'maxOutputTokens': 128,
              'temperature': 0.7,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
          return _saveAndReturnRecap(report, text.trim());
        } else {
          print('[LLM] Gemini API error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('[LLM] Gemini generation error: $e');
      }
    }

    // 4. Fallback to Templates
    print('[LLM] Falling back to templates.');
    report.isAiGenerated = false;
    await DbService.instance.isar.writeTxn(() async {
      await DbService.instance.wrappedReports.put(report);
    });
    return _generateLocal(report);
  }

  Future<String> _saveAndReturnRecap(WrappedReport report, String result) async {
    print('[LLM] Generation success!');
    report.llmRecap = result;
    report.isAiGenerated = true;
    await DbService.instance.isar.writeTxn(() async {
      await DbService.instance.wrappedReports.put(report);
    });
    return result;
  }

  String _buildPrompt(WrappedReport report, String? lyricsSnippet) {
    String topGenres = '';
    try {
      final Map<String, dynamic> genres = jsonDecode(report.genreJsonStr);
      final sorted = genres.entries.toList()..sort((a, b) => (b.value as int).compareTo(a.value as int));
      topGenres = sorted.take(3).map((e) => e.key).join(', ');
    } catch (_) {}

    String prompt = "Write a short, punchy, personality-driven 2-sentence summary of my music taste for this ${report.periodLabel}. "
        "Top genres and mood: $topGenres. "
        "Top artist: ${report.topArtist} (${report.topArtistPlays} plays). "
        "Peak hour: ${report.peakHourLabel}. "
        "Personality type: ${report.personalityType}. "
        "Listening streak: ${report.streakDays} days. ";

    if (lyricsSnippet != null && lyricsSnippet.isNotEmpty) {
       prompt += "My top song is '${report.topSong}', here are some lyrics: \"$lyricsSnippet\". Reference them creatively! ";
    }

    prompt += "Focus heavily on the mood and genres rather than pure listening timeframe. Be casual and use modern lingo.";
    return prompt;
  }

  Future<List<SmartPlaylistData>> generateSmartPlaylists() async {
    // Return cache if it's less than 30 mins old
    if (_cachedPlaylists != null && 
        _lastPlaylistUpdate != null && 
        DateTime.now().difference(_lastPlaylistUpdate!).inMinutes < 30) {
      return _cachedPlaylists!;
    }

    final db = DbService.instance;
    final allSongs = await db.songs.where().filter().isHiddenEqualTo(false).findAll();
    if (allSongs.isEmpty) return [];

    final genreMap = <String, List<Song>>{};
    final artistMap = <String, List<Song>>{};
    
    for (var s in allSongs) {
      final normalizedGenre = s.genre.trim().split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
      if (normalizedGenre.isNotEmpty && normalizedGenre != 'Unknown' && normalizedGenre != '<unknown>') {
        genreMap.putIfAbsent(normalizedGenre, () => []).add(s);
      }
      
      final normalizedArtist = s.artist.trim().split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
      if (normalizedArtist.isNotEmpty && normalizedArtist != 'Unknown Artist' && normalizedArtist != 'Unknown') {
        artistMap.putIfAbsent(normalizedArtist, () => []).add(s);
      }
    }

    final sortedGenres = genreMap.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    final sortedArtists = artistMap.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    final fallbacks = {
      'Rock': 'Electric Reverie',
      'Pop': 'Bubblegum Crisis',
      'Jazz': 'Midnight Noir',
      'Hip Hop': 'Concrete Jungle',
      'Chill': 'Cloud Nine',
      'Classical': 'Eternal Echoes',
      'Country': 'Dusty Roads',
      'Electronic': 'Neon Dreams',
    };

    final result = <SmartPlaylistData>[];
    
    // 1. Try Genre-based playlists
    for (var i = 0; i < sortedGenres.length && i < 3; i++) {
        final genre = sortedGenres[i].key;
        final songs = sortedGenres[i].value;
        if (songs.length < 3) continue;

        String name = fallbacks[genre] ?? '$genre Vibes';
        bool isAi = false;

        if (_modelAvailable && _llama != null) {
          try {
            final prompt = "Give me one highly creative, catchy, and twisty name for a playlist featuring $genre music. Return ONLY the name. No quotes or intro.";
            _llama!.setPrompt("<s>[INST] $prompt [/INST]");
            final response = await _llama!.generateCompleteText(maxTokens: 32);
            if (response.isNotEmpty) {
               name = response.trim().replaceAll('"', '');
               isAi = true;
            }
          } catch (_) {}
        }
        
        result.add(SmartPlaylistData(name: name, songs: songs, isAiGenerated: isAi));
    }

    // 2. "The Vault" (Old favorites - played many times but not recently)
    final vaultSongs = allSongs.where((s) => s.playCount > 5 && (s.lastPlayedAt == null || DateTime.now().difference(s.lastPlayedAt!).inDays > 7)).toList();
    if (vaultSongs.isNotEmpty) {
      result.add(SmartPlaylistData(
        name: 'The Vault', 
        songs: (vaultSongs..shuffle()).take(15).toList(),
        isAiGenerated: false,
      ));
    }

    // 3. "Discovery" (Unused songs)
    final discoverySongs = allSongs.where((s) => s.playCount <= 1).toList();
    if (discoverySongs.isNotEmpty) {
      result.add(SmartPlaylistData(
        name: 'Discovery Lane', 
        songs: (discoverySongs..shuffle()).take(15).toList(),
        isAiGenerated: false,
      ));
    }

    // Fallback: Mixed Mix
    if (result.length < 2 && allSongs.isNotEmpty) {
      final mixed = List<Song>.from(allSongs)..shuffle();
      result.add(SmartPlaylistData(
        name: 'The Daily Mix: Reloaded', 
        songs: mixed.take(20).toList(),
        isAiGenerated: false,
      ));
    }

    _cachedPlaylists = result;
    _lastPlaylistUpdate = DateTime.now();
    return result;
  }

  Future<MapEntry<Song, String>?> generateNextVibeSong(Song currentSong) async {
    final db = DbService.instance;
    final allSongs = await db.songs.where().filter().isHiddenEqualTo(false).findAll();
    if (allSongs.isEmpty) return null;

    var candidates = allSongs.where((s) => s.id != currentSong.id && (s.genre == currentSong.genre || s.artist == currentSong.artist)).toList();
    if (candidates.isEmpty) {
      candidates = allSongs.where((s) => s.id != currentSong.id).toList();
    }
    if (candidates.isEmpty) return null;

    candidates.shuffle();
    final nextSong = candidates.first;

    String transition = "Up next: ${nextSong.title}";

    if (_modelAvailable && _llama != null) {
      try {
        final prompt = "You are a fun music DJ. The current song is '${currentSong.title}' by ${currentSong.artist}. The next song is '${nextSong.title}' by ${nextSong.artist}. Write a super short 1-sentence DJ voiceover introducing the next song.";
        print('[LLM] Generating AI DJ Transition...');
        // Removed prompt logging for production privacy

        
        final fullPrompt = "<s>[INST] $prompt [/INST]";
        _llama!.setPrompt(fullPrompt);
        final response = await _llama!.generateCompleteText(maxTokens: 64);
        if (response.isNotEmpty) {
           transition = response.trim().replaceAll('"', '');
           print('[LLM] Generated DJ Intro: $transition');
        }
      } catch (e) {
        print('[LLM] AI DJ generation error: $e');
      }
    } else {
      print('[LLM] AI DJ skipping LLM (Model not available). Using templates.');
      final templates = [
        "Keeping the vibes flowing, here's ${nextSong.title} by ${nextSong.artist}.",
        "That was ${currentSong.title}. Now let's jump into ${nextSong.title}.",
        "You're locked in. Up next is ${nextSong.artist} with ${nextSong.title}.",
        "Don't touch that dial, we're jumping straight into ${nextSong.title}.",
        "Next track coming right up: ${nextSong.title}."
      ];
      templates.shuffle();
      transition = templates.first;
    }

    return MapEntry(nextSong, transition);
  }

  // ── Local template-based generator ──────────────────────────
  //
  // Uses structured stats to produce authentic, punchy Wrapped text.
  // Multiple templates keep it feeling fresh across different reports.

  String _generateLocal(WrappedReport report) {
    final templates = [
      'You had a cinematic ${report.periodLabel}. '
          '${report.topArtist} carried you through the best and worst moments '
          'with ${report.topArtistPlays} plays. '
          'Your ${report.personalityType} energy peaked at ${report.peakHourLabel} — '
          "and honestly? We stan the dedication.",

      '${report.periodLabel} was YOUR era. '
          '${report.topArtist} was on repeat (${report.topArtistPlays} times, no shame). '
          'You vibed hardest at ${report.peakHourLabel}. '
          '${report.streakDays}-day streak? That\'s called commitment.',

      'Let\'s talk about your ${report.periodLabel}. '
          '${report.topArtist} dominated your ears — ${report.topArtistPlays} plays strong. '
          'Peak hours: ${report.peakHourLabel}. '
          'Personality: ${report.personalityType}. Verdict: immaculate taste.',

      '${report.totalMinutes} minutes of pure emotion this ${report.periodLabel}. '
          '${report.topArtist} was your ride-or-die artist. '
          'You hit a ${report.streakDays}-day listening streak and peaked at ${report.peakHourLabel}. '
          'A ${report.personalityType} through and through.',
      'This ${report.periodLabel}, you didn\'t just listen - you felt it. '
      '${report.topArtist} led the soundtrack with ${report.topArtistPlays} plays. '
      'Your peak moment? ${report.peakHourLabel}. '
      '${report.personalityType} energy all the way.',

      'Main character energy detected this ${report.periodLabel}. '
          '${report.topArtist} was your go-to (${report.topArtistPlays} plays). '
          'You owned ${report.peakHourLabel} like it was your personal stage. '
          '${report.streakDays}-day streak? Icon behavior.',

      'Your ${report.periodLabel} was basically a curated playlist. '
          '${report.topArtist} took the spotlight with ${report.topArtistPlays} plays. '
          'Peak listening at ${report.peakHourLabel}, of course. '
          '${report.personalityType} mood = unmatched.',

      '${report.totalMinutes} minutes, zero skips (we assume). '
          '${report.topArtist} stayed on top with ${report.topArtistPlays} plays. '
          'You showed up most at ${report.peakHourLabel}. '
          '${report.streakDays}-day streak? Elite consistency.',

      'If this ${report.periodLabel} had a theme song, it was ${report.topArtist}. '
          '${report.topArtistPlays} plays says it all. '
          'You thrived at ${report.peakHourLabel} — peak vibes only. '
          '${report.personalityType} energy certified.',

      'You understood the assignment this ${report.periodLabel}. '
          '${report.topArtist} carried hard (${report.topArtistPlays} plays). '
          '${report.peakHourLabel} was your power hour. '
          'And that ${report.streakDays}-day streak? Respect.',

      'Your listening stats are telling a story this ${report.periodLabel}. '
          '${report.topArtist}: ${report.topArtistPlays} plays. '
          'Peak time: ${report.peakHourLabel}. '
          'Conclusion: ${report.personalityType} and thriving.',

      'No one was doing it like you this ${report.periodLabel}. '
          '${report.topArtist} dominated your queue (${report.topArtistPlays} plays). '
          'You peaked at ${report.peakHourLabel} — naturally. '
          '${report.streakDays}-day streak locked in.',

      'This ${report.periodLabel} was powered by vibes. '
          '${report.topArtist} delivered ${report.topArtistPlays} times. '
          'You showed up strongest at ${report.peakHourLabel}. '
          '${report.personalityType} energy never missed.',

      'A recap of your ${report.periodLabel}? Say less. '
          '${report.topArtist} on repeat (${report.topArtistPlays} plays). '
          '${report.peakHourLabel} was your golden hour. '
          '${report.streakDays}-day streak = no breaks, just vibes.',

      'You built a whole universe this ${report.periodLabel}. '
          '${report.topArtist} was the soundtrack (${report.topArtistPlays} plays). '
          'Peak listening at ${report.peakHourLabel}. '
          '${report.personalityType} aura: undeniable.',

      'Stats don\'t lie - this ${report.periodLabel} was iconic. '
          '${report.topArtist} led with ${report.topArtistPlays} plays. '
          '${report.peakHourLabel} was your moment. '
          '${report.streakDays}-day streak? Legendary behavior.',

        'This ${report.periodLabel}, you were in your feelings (and your playlist). '
      '${report.topArtist} led the charge with ${report.topArtistPlays} plays. '
      '${report.peakHourLabel} was your moment. No skips, just vibes.',

      'You really said "run it back" this ${report.periodLabel}. '
          '${report.topArtist} played ${report.topArtistPlays} times. '
          'Peak hour? ${report.peakHourLabel}. '
          'We see you.',

      'Your ${report.periodLabel} was powered by repetition. '
          '${report.topArtist} stayed undefeated (${report.topArtistPlays} plays). '
          '${report.streakDays}-day streak? That\'s discipline.',

      'Some people listened. You *committed* this ${report.periodLabel}. '
          '${report.topArtist} with ${report.topArtistPlays} plays says it all. '
          'Peak at ${report.peakHourLabel}.',

      'This ${report.periodLabel}, you found your loop and stayed in it. '
          '${report.topArtist} carried (${report.topArtistPlays} plays). '
          '${report.personalityType} energy, no doubt.',

      'Your music taste? Loud and clear this ${report.periodLabel}. '
          '${report.topArtist} dominated your plays (${report.topArtistPlays}). '
          '${report.peakHourLabel} was your peak zone.',

      'You had one mission this ${report.periodLabel}: vibes. '
          '${report.topArtist} delivered ${report.topArtistPlays} times. '
          '${report.streakDays}-day streak? Mission accomplished.',

      'Let\'s not pretend - ${report.topArtist} WAS your ${report.periodLabel}. '
          '${report.topArtistPlays} plays later, still iconic. '
          '${report.peakHourLabel} was your prime time.',

      'This ${report.periodLabel}, you pressed play and never looked back. '
          '${report.topArtist} stayed on repeat (${report.topArtistPlays} plays). '
          '${report.personalityType} mood locked in.',

      'You curated chaos this ${report.periodLabel}. '
          '${report.topArtist} led with ${report.topArtistPlays} plays. '
          '${report.peakHourLabel} was your peak energy window.',

      'If obsession had stats, this would be it. '
          '${report.topArtist}: ${report.topArtistPlays} plays this ${report.periodLabel}. '
          'No explanation needed.',

      'You really built a routine this ${report.periodLabel}. '
          '${report.topArtist} stayed on top (${report.topArtistPlays} plays). '
          '${report.streakDays}-day streak? Consistency wins.',

      'This ${report.periodLabel}, your headphones worked overtime. '
          '${report.totalMinutes} minutes and counting. '
          '${report.topArtist} carried the playlist.',

      'You unlocked a new level of listening this ${report.periodLabel}. '
          '${report.topArtist} hit ${report.topArtistPlays} plays. '
          '${report.peakHourLabel} = peak performance.',

      'No one was looping like you this ${report.periodLabel}. '
          '${report.topArtist} (${report.topArtistPlays} plays). '
          'That\'s dedication.',

      'Your ${report.periodLabel} had one rule: play it again. '
          '${report.topArtist} dominated your stats (${report.topArtistPlays} plays). '
          '${report.personalityType} energy stayed consistent.',

      'This ${report.periodLabel}, you trusted the algorithm — and yourself. '
          '${report.topArtist} came out on top (${report.topArtistPlays} plays). '
          '${report.peakHourLabel} was your zone.',

      'A quick recap of your ${report.periodLabel}: '
          '${report.topArtist}, ${report.topArtistPlays} plays, '
          '${report.streakDays}-day streak, and zero regrets.',

      'You stayed loyal this ${report.periodLabel}. '
          '${report.topArtist} led every session (${report.topArtistPlays} plays). '
          '${report.peakHourLabel}? Right on schedule.',

      'Your listening pattern this ${report.periodLabel}? Predictable — in the best way. '
          '${report.topArtist} stayed on repeat (${report.topArtistPlays}). '
          '${report.personalityType} energy confirmed.',

      'This ${report.periodLabel}, you didn\'t chase trends - you made habits. '
          '${report.topArtist} carried (${report.topArtistPlays} plays). '
          '${report.streakDays}-day streak locked in.',

      'You turned moments into music this ${report.periodLabel}. '
          '${report.topArtist} was there ${report.topArtistPlays} times. '
          '${report.peakHourLabel} hit different.',

      'Let\'s summarize your ${report.periodLabel}: '
          'repeat, repeat, repeat. '
          '${report.topArtist} with ${report.topArtistPlays} plays. Enough said.',

      'This ${report.periodLabel}, your playlist had a clear favorite. '
          '${report.topArtist} (${report.topArtistPlays} plays). '
          'No competition.',

      'You stayed in your zone this ${report.periodLabel}. '
          '${report.topArtist} led your stats (${report.topArtistPlays}). '
          '${report.peakHourLabel} was your comfort hour.',

      'You didn\'t switch it up - and it worked. '
          '${report.topArtist} dominated your ${report.periodLabel} (${report.topArtistPlays} plays). '
          '${report.personalityType} energy stayed strong.',
    ];

    // Pick template based on month/stats to get variety
    final index = (report.totalMinutes + report.topArtistPlays) % templates.length;
    return templates[index];
  }
}
