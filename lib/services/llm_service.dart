// services/llm_service.dart
// Local on-device text generator for Wrapped recaps.
// Attempts to use fllama (TinyLlama GGUF) if a model file exists on-device.
// Falls back to smart template-based generation (no external API calls).
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
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
  static const _aiEnabledPref = 'llm_ai_enabled';
  static const _modelNamePref = 'llm_model_name';

  String _cachedApiKey = '';
  String _modelPath = '';
  LlamaController? _llama;
  bool _modelAvailable = false;
  bool _modelLoaded = false;
  bool _isAiEnabled = true;

  final modelStatus = ValueNotifier<String?>(null);
  final modelName = ValueNotifier<String?>(null);
  final generationProgress = ValueNotifier<int>(0);
  List<SmartPlaylistData>? _cachedPlaylists;
  DateTime? _lastPlaylistUpdate;
  Future<void>? _loadFuture;

  bool get isAiEnabled => _isAiEnabled;
  bool get isModelLoaded => _modelLoaded;

  Future<String> get currentApiKey async {
    if (_cachedApiKey.isNotEmpty) return _cachedApiKey;
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = prefs.getString(_apiKeyPref) ?? '';
    return _cachedApiKey;
  }

  Future<void> updateApiKey(String key) async {
    _cachedApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  Future<String> get currentModelPath async {
    if (_modelPath.isNotEmpty) return _modelPath;
    final prefs = await SharedPreferences.getInstance();
    _modelPath = prefs.getString(_modelPathPref) ?? '';
    return _modelPath;
  }

  Future<void> updateModelPath(String path) async {
    _modelPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPathPref, path);
    _modelAvailable = path.isNotEmpty && await File(path).exists();
  }

  Future<void> loadModel([String? modelPath]) async {
    final prefs = await SharedPreferences.getInstance();
    _isAiEnabled = prefs.getBool(_aiEnabledPref) ?? true;
    modelName.value = prefs.getString(_modelNamePref);

    if (!_isAiEnabled) {
      modelStatus.value = "AI Sleeping (RAM freed)";
      return;
    }
    _loadFuture = _loadModelInternal(modelPath);
    return _loadFuture;
  }

  Future<void> setAiEnabled(bool enabled) async {
    _isAiEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledPref, enabled);

    if (enabled) {
      final path = await currentModelPath;
      if (path.isNotEmpty) {
        await loadModel(path);
      } else {
        modelStatus.value = "No model file selected";
      }
    } else {
      await disposeModel();
      modelStatus.value = "AI Sleeping (RAM freed)";
    }
  }

  Future<void> _loadModelInternal([String? modelPath]) async {
    final path = modelPath ?? await currentModelPath;
    if (path.isEmpty) return;

    File modelFile = File(path);
    if (!await modelFile.exists()) {
      _modelAvailable = false;
      return;
    }

    bool isCachePath = path.contains('/cache/') || path.contains('/com.android.providers');
    final docDir = await getApplicationDocumentsDirectory();
    bool isAlreadyInDocs = path.contains(docDir.path);

    final originalName = path.split('/').last;
    if (modelName.value == null || modelName.value != originalName) {
      modelName.value = originalName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelNamePref, originalName);
    }

    if (isCachePath && !isAlreadyInDocs) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final newPath = '${docDir.path}/model.gguf';

        if (path != newPath) {
          print('[LLM] Moving model to internal storage for persistence...');
          final newFile = File(newPath);

          if (await newFile.exists()) await newFile.delete();
          await modelFile.copy(newPath);

          modelFile = newFile;
          await updateModelPath(newPath);
          print('[LLM] Model persisted at: $newPath');
        }
      } catch (e) {
        print('[LLM] Failed to persist model: $e');
        print('[LLM] Proceeding with temporary cache path...');
      }
    }

    await disposeModel();

    try {
      modelStatus.value = "Loading model into RAM...";
      print('[LLM] Attempting to load model from: ${modelFile.path}');
      _llama = LlamaController();
      await _llama!.loadModel(modelPath: modelFile.path);

      _modelAvailable = true;
      _modelLoaded = true;
      _modelPath = modelFile.path;
      modelStatus.value = "Model Ready (Local AI Active)";
      print('[LLM] Model loaded successfully');
    } catch (e) {
      final errorStr = e.toString();
      String userMessage = errorStr;

      if (errorStr.contains('libllama.so') || errorStr.contains('dlopen failed')) {
        userMessage = 'Native library incompatible. Use physical ARM64 device.';
      }

      print('[LLM] Error loading model: $userMessage');
      modelStatus.value = "Error: $userMessage";
      _modelAvailable = false;
      _modelLoaded = false;
      throw Exception(userMessage);
    }
  }

  Future<void> disposeModel() async {
    try {
      if (_modelLoaded || _llama != null) {
        modelStatus.value = "Unloading model...";
        await _llama?.dispose();
        _llama = null;
        _modelLoaded = false;
        _modelAvailable = false;
        modelStatus.value = "Model unloaded (RAM freed)";
      }
    } catch (e) {
      print('[LLM] Error disposing model: $e');
      modelStatus.value = "Error unloading: $e";
    }
  }

  Future<void> clearModel() async {
    await disposeModel();
    final path = await currentModelPath;
    if (path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modelNamePref);
    modelName.value = null;

    await updateModelPath('');
    modelStatus.value = "Model cleared (File deleted)";
  }

  // ── Core prompt builder for tiny local LLMs ───────────────────────────────
  // Designed for TinyLlama-1.1B, Gemma-3-1B, and Llama-3.2-1B-Instruct Q5_K_M.
  // Rules: short context, no multi-turn, direct fill-in format, no meta-commentary.
  // All prompts use a "fill in the blank" pattern so the model just continues text
  // rather than answering — dramatically reduces hallucination on sub-2B models.

  /// Wraps a prompt for the detected/assumed model format.
  String _wrapPrompt(String instruction, String responsePrefix) {
    final name = (modelName.value ?? '').toLowerCase();
    if (name.contains('gemma')) {
      return '<start_of_turn>user\n$instruction<end_of_turn>\n<start_of_turn>model\n$responsePrefix';
    }
    return '<s>[INST] $instruction [/INST]\n$responsePrefix';
  }

  // ── AI-driven song curation ───────────────────────────────────────────────
  //
  // Instead of just renaming a shuffle, the LLM scores each song against a
  // "vibe profile" derived from the user's listening behaviour. The score is
  // a weighted sum of three on-device signals so nothing leaves the device:
  //
  //   playScore  — normalised play-count (loyalty signal)
  //   freshScore — recency of last play   (momentum signal)
  //   moodScore  — LLM vibe-match        (0 or 1, only when model is loaded)
  //
  // Without LLM the first two signals still produce a meaningfully different
  // ordering from a raw shuffle, so algo playlists also improve.

  /// Derives a compact "vibe tag" for a song from its metadata.
  /// Used as a lightweight stand-in for audio-feature analysis.
  String _songVibeTag(Song song) {
    final g = song.genre.toLowerCase();
    if (g.contains('lo-fi') || g.contains('chill') || g.contains('ambient')) return 'chill';
    if (g.contains('rock') || g.contains('metal') || g.contains('punk')) return 'energetic';
    if (g.contains('jazz') || g.contains('blues') || g.contains('soul')) return 'soulful';
    if (g.contains('pop') || g.contains('indie')) return 'upbeat';
    if (g.contains('hip') || g.contains('rap') || g.contains('trap')) return 'hype';
    if (g.contains('classical') || g.contains('orchestral')) return 'focused';
    if (g.contains('electronic') || g.contains('edm') || g.contains('dance')) return 'electric';
    if (g.contains('country') || g.contains('folk') || g.contains('acoustic')) return 'mellow';
    // Fallback: infer from play-count momentum
    if (song.playCount > 20) return 'energetic';
    if (song.playCount > 10) return 'upbeat';
    return 'chill';
  }

  /// Ask the LLM to pick the best vibe-tag for a playlist theme in one token.
  /// Returns one of: chill | energetic | soulful | upbeat | hype | focused | electric | mellow
  Future<String> _askLlmForVibeTag(String genre, String activityHint) async {
    if (!_modelAvailable || !_modelLoaded || _llama == null || !_isAiEnabled) return '';

    const tags = 'chill, energetic, soulful, upbeat, hype, focused, electric, mellow';
    final instruction =
        'A listener who loves $genre music is about to listen $activityHint. '
        'Which single word best describes the ideal vibe? '
        'Choose ONLY one from: $tags. Output only the one word.';
    final prompt = _wrapPrompt(instruction, 'Vibe:');

    try {
      if (!_modelLoaded || _llama == null) return '';
      final stream = _llama!.generate(prompt: prompt, maxTokens: 6);
      String raw = '';
      await for (final token in stream) {
        if (!_modelLoaded || _llama == null) break;
        raw += token;
        if (raw.length > 30) break; // safety cap
      }
      final word = raw
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z]'), ' ')
          .trim()
          .split(' ')
          .firstWhere(
            (w) => ['chill','energetic','soulful','upbeat','hype','focused','electric','mellow'].contains(w),
            orElse: () => '',
          );
      print('[LLM] Vibe tag for $genre: $word');
      return word;
    } catch (e) {
      print('[LLM] Vibe tag error: $e');
      return '';
    }
  }

  /// Returns a 0-1 float: how strongly does this song match the target vibe?
  double _vibeMatchScore(Song song, String targetVibe) {
    if (targetVibe.isEmpty) return 0.5; // neutral — no LLM result
    final songVibe = _songVibeTag(song);
    if (songVibe == targetVibe) return 1.0;

    // Partial affinity map — similar vibes score 0.6 instead of 0
    const affinity = <String, List<String>>{
      'chill':     ['mellow', 'focused', 'soulful'],
      'energetic': ['hype', 'electric', 'upbeat'],
      'soulful':   ['chill', 'mellow', 'upbeat'],
      'upbeat':    ['energetic', 'electric', 'soulful'],
      'hype':      ['energetic', 'electric', 'upbeat'],
      'focused':   ['chill', 'mellow'],
      'electric':  ['energetic', 'hype', 'upbeat'],
      'mellow':    ['chill', 'focused', 'soulful'],
    };
    final related = affinity[targetVibe] ?? [];
    return related.contains(songVibe) ? 0.6 : 0.1;
  }

  /// Scores and sorts songs for a playlist. Pure Dart — fast, no LLM call here.
  List<Song> _curateByScore(List<Song> songs, String targetVibe, {int limit = 20}) {
    final now = DateTime.now();
    final maxPlays = songs.fold<int>(1, (m, s) => s.playCount > m ? s.playCount : m);

    final scored = songs.map((song) {
      // 1. Play loyalty (0–1)
      final playScore = song.playCount / maxPlays;

      // 2. Recency momentum (0–1, decays over 30 days)
      double freshScore = 0.0;
      if (song.lastPlayedAt != null) {
        final daysAgo = now.difference(song.lastPlayedAt!).inDays;
        freshScore = (1.0 - (daysAgo / 30.0)).clamp(0.0, 1.0);
      }

      // 3. Vibe match (0, 0.6, or 1.0)
      final moodScore = _vibeMatchScore(song, targetVibe);

      // Weighted composite — mood is the dominant signal for AI playlists
      final total = (moodScore * 0.55) + (playScore * 0.25) + (freshScore * 0.20);
      return MapEntry(song, total);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take the top scored songs, then lightly shuffle the top half
    // to avoid a perfectly identical list every time.
    final topN = scored.take(limit * 2).map((e) => e.key).toList();
    if (topN.length > 4) {
      final half = (topN.length / 2).ceil();
      final top = topN.sublist(0, half)..shuffle();
      final rest = topN.sublist(half);
      return [...top, ...rest].take(limit).toList();
    }
    return topN.take(limit).toList();
  }

  /// Activity hint from current hour — used to prime the vibe selection.
  String _activityHintFromHour() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 9)   return 'during their morning routine';
    if (h >= 9 && h < 12)  return 'while working or studying';
    if (h >= 12 && h < 14) return 'on a lunch break';
    if (h >= 14 && h < 17) return 'during an afternoon grind';
    if (h >= 17 && h < 20) return 'winding down after work';
    if (h >= 20 && h < 23) return 'relaxing in the evening';
    return 'late at night';
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// Generate a Wrapped recap paragraph.
  Future<String> generateWrappedRecap(WrappedReport report) async {
    await _loadFuture;
    generationProgress.value = 0;

    if (report.llmRecap.isNotEmpty) {
      print('[LLM] Using cached recap for ${report.periodLabel}');
      return report.llmRecap;
    }

    String? lyricsSnippet;
    try {
      final db = DbService.instance;
      final song = await db.songs
          .filter()
          .titleEqualTo(report.topSong)
          .isHiddenEqualTo(false)
          .findFirst();
      if (song != null) {
        final lyrics = await LyricsService.instance.fetchLyrics(song);
        if (lyrics != null && lyrics.isNotEmpty) {
          lyricsSnippet = lyrics.replaceAll(RegExp(r'\[.*?\]'), ' ').trim();
          if (lyricsSnippet.length > 150) lyricsSnippet = lyricsSnippet.substring(0, 150);
        }
      }
    } catch (_) {}

    final prompt = _buildRecapPrompt(report, lyricsSnippet);

    // 1. Try Local GGUF
    if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
      try {
        print('[LLM] Generating recap via Local GGUF...');
        if (!_modelLoaded || _llama == null) return _generateLocal(report);

        final stream = _llama!.generate(prompt: prompt, maxTokens: 80);
        String response = '';
        await for (final token in stream) {
          if (!_modelLoaded || _llama == null) break;
          response += token;
          generationProgress.value++;
        }

        if (response.isNotEmpty) {
          final cleaned = _cleanLlmResponse(response);
          if (cleaned.length > 20) return _saveAndReturnRecap(report, cleaned);
        }
      } catch (e) {
        print('[LLM] Local recap error: $e');
      }
    }

    // 2. Try Gemini API
    final apiKey = await currentApiKey;
    if (apiKey.isNotEmpty) {
      try {
        print('[LLM] Generating recap via Gemini API...');
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': _buildRecapPromptRaw(report, lyricsSnippet)}
                ]
              }
            ],
            'generationConfig': {'maxOutputTokens': 80, 'temperature': 0.7}
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
          return _saveAndReturnRecap(report, text.trim());
        }
      } catch (e) {
        print('[LLM] Gemini recap error: $e');
      }
    }

    // 3. Template fallback
    print('[LLM] Falling back to templates.');
    report.isAiGenerated = false;
    await DbService.instance.isar.writeTxn(() async {
      await DbService.instance.wrappedReports.put(report);
    });
    return _generateLocal(report);
  }

  // ── RECAP PROMPTS ─────────────────────────────────────────────────────────
  //
  // The old prompts fed raw facts ("top artist X, plays Y") and the model
  // echoed them back as statements. New approach:
  //   1. Facts are hidden behind a single adjective the model must *interpret*
  //   2. The model is told it's writing about a *person*, not a stat sheet
  //   3. Fill-in prefix anchors the voice immediately so the model can't pivot
  //      to listing facts before the token budget runs out

  /// Prompt for local tiny LLMs — personality-first, fact-light.
  String _buildRecapPrompt(WrappedReport report, String? lyricsSnippet) {
    final topGenre = _getTopGenre(report);
    final loyalty = report.topArtistPlays > 50
        ? 'obsessively'
        : report.topArtistPlays > 20
            ? 'deeply'
            : 'consistently';
    final timeVibe = _peakHourVibe(report.peakHour);

    // Fill-in format: model must continue the opening sentence in a vivid,
    // personality-driven voice. Facts only leak in as colour, not the point.
    final instruction =
        'You are a snarky music personality writing a 2-sentence vibe check '
        'about a listener. Capture their soul, not their stats. '
        'They are $loyalty into $topGenre, a $timeVibe listener, '
        'and their spirit animal right now is ${report.topArtist}. '
        'Be punchy, poetic, second-person. No numbers. No lists.';

    return _wrapPrompt(instruction, 'You are the type of person who');
  }

  /// Plain instruction for Gemini (cloud API handles longer prompts fine).
  String _buildRecapPromptRaw(WrappedReport report, String? lyricsSnippet) {
    final topGenre = _getTopGenre(report);
    final loyalty = report.topArtistPlays > 50
        ? 'obsessively'
        : report.topArtistPlays > 20
            ? 'deeply'
            : 'consistently';
    final timeVibe = _peakHourVibe(report.peakHour);

    return 'Write a 2-sentence music personality vibe-check for ${report.periodLabel}. '
        'Speak directly to the listener in second person. '
        'They are $loyalty into $topGenre music. '
        'They are a $timeVibe listener whose current obsession is ${report.topArtist}. '
        'Do NOT list stats or numbers. Capture the *feeling* and personality — '
        'like a witty horoscope for a music lover. '
        '${lyricsSnippet != null ? 'Optional flavour from their top song: "$lyricsSnippet" — weave the mood in subtly, never quote it.' : ''} '
        'Output only the 2 sentences.';
  }

  /// Maps a peak hour int → a human vibe string for use in prompts.
  String _peakHourVibe(int hour) {
    if (hour >= 0 && hour < 5) return 'deep-night insomniac';
    if (hour >= 5 && hour < 9) return 'early-morning ritual';
    if (hour >= 9 && hour < 12) return 'focused midmorning';
    if (hour >= 12 && hour < 15) return 'lunch-hour escape';
    if (hour >= 15 && hour < 18) return 'late-afternoon grind';
    if (hour >= 18 && hour < 21) return 'golden-hour wind-down';
    return 'late-night overthinker';
  }

  Future<String> _saveAndReturnRecap(WrappedReport report, String result) async {
    print('[LLM] Recap saved!');
    report.llmRecap = result;
    report.isAiGenerated = true;
    await DbService.instance.isar.writeTxn(() async {
      await DbService.instance.wrappedReports.put(report);
    });
    return result;
  }

  // ── SMART PLAYLISTS ───────────────────────────────────────────────────────
  //
  // Three tiers:
  //   ALGO  — sorted by (playScore + freshScore), labelled with a static name
  //   AI    — LLM picks a vibe tag → songs scored by vibe match + play + recency
  //           → LLM also picks the playlist name
  //   FIXED — The Vault, Discovery Lane, Artist Ritual (unchanged logic)

  Future<List<SmartPlaylistData>> generateSmartPlaylists() async {
    await _loadFuture;

    if (_cachedPlaylists != null &&
        _lastPlaylistUpdate != null &&
        DateTime.now().difference(_lastPlaylistUpdate!).inMinutes < 30) {
      return _cachedPlaylists!;
    }

    final db = DbService.instance;
    final allSongs =
        await db.songs.where().filter().isHiddenEqualTo(false).findAll();
    if (allSongs.isEmpty) return [];

    final genreMap = <String, List<Song>>{};
    final artistMap = <String, List<Song>>{};

    for (var s in allSongs) {
      final normalizedGenre = s.genre
          .trim()
          .split(' ')
          .map((word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join(' ');
      if (normalizedGenre.isNotEmpty &&
          normalizedGenre != 'Unknown' &&
          normalizedGenre != '<unknown>') {
        genreMap.putIfAbsent(normalizedGenre, () => []).add(s);
      }

      final normalizedArtist = s.artist
          .trim()
          .split(' ')
          .map((word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase())
          .join(' ');
      if (normalizedArtist.isNotEmpty &&
          normalizedArtist != 'Unknown Artist' &&
          normalizedArtist != 'Unknown') {
        artistMap.putIfAbsent(normalizedArtist, () => []).add(s);
      }
    }

    final sortedGenres = genreMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final sortedArtists = artistMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final fallbackNames = <String, String>{
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
    final activityHint = _activityHintFromHour();

    // ── Genre-based playlists (top 5) ──────────────────────────────────────
    for (var i = 0; i < sortedGenres.length && i < 5; i++) {
      final genre = sortedGenres[i].key;
      final songs = sortedGenres[i].value;
      if (songs.length < 3) continue;

      // A. ALGO playlist — ranked by play loyalty + recency (no LLM needed)
      final algoSongs = _curateByScore(songs, '', limit: 20);
      final algoName = fallbackNames[genre] ?? '$genre Vibes';
      result.add(SmartPlaylistData(
        name: algoName,
        songs: algoSongs,
        isAiGenerated: false,
      ));

      // B. AI playlist — LLM picks vibe → curate songs → LLM picks name
      if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
        try {
          generationProgress.value = 0;

          // Step 1: ask LLM what vibe fits this genre + current activity
          final vibeTag = await _askLlmForVibeTag(genre, activityHint);

          // Step 2: curate songs by vibe score (different from algo order)
          final aiSongs = _curateByScore(songs, vibeTag, limit: 20);

          // Step 3: ask LLM for a name that reflects both genre + vibe
          final aiName = await _generateAiPlaylistName(genre, vibeTag);

          if (aiName.isNotEmpty &&
              aiName.toLowerCase() != algoName.toLowerCase()) {
            result.add(SmartPlaylistData(
              name: aiName,
              songs: aiSongs,
              isAiGenerated: true,
            ));
            print('[LLM] AI playlist "$aiName" ($vibeTag) — ${aiSongs.length} songs');
          }
        } catch (e) {
          print('[LLM] AI playlist error: $e');
        }
      }
    }

    // ── Artist Ritual playlists (top 3) ────────────────────────────────────
    for (var i = 0; i < sortedArtists.length && i < 3; i++) {
      final artist = sortedArtists[i].key;
      final songs = sortedArtists[i].value;
      if (songs.length < 4) continue;

      // Sort by play count desc so most-loved songs lead the ritual
      final ritualSongs = List<Song>.from(songs)
        ..sort((a, b) => b.playCount.compareTo(a.playCount));
      result.add(SmartPlaylistData(
        name: '$artist Ritual',
        songs: ritualSongs.take(15).toList(),
        isAiGenerated: false,
      ));
    }

    // ── The Vault (old favourites not heard recently) ─────────────────────
    final vaultSongs = allSongs
        .where((s) =>
            s.playCount > 5 &&
            (s.lastPlayedAt == null ||
                DateTime.now().difference(s.lastPlayedAt!).inDays > 7))
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    if (vaultSongs.isNotEmpty) {
      result.add(SmartPlaylistData(
        name: 'The Vault',
        songs: vaultSongs.take(15).toList(),
        isAiGenerated: false,
      ));
    }

    // ── Discovery Lane (unplayed or barely played) ────────────────────────
    final discoverySongs = allSongs.where((s) => s.playCount <= 1).toList()
      ..shuffle();
    if (discoverySongs.isNotEmpty) {
      result.add(SmartPlaylistData(
        name: 'Discovery Lane',
        songs: discoverySongs.take(15).toList(),
        isAiGenerated: false,
      ));
    }

    // ── Fallback: mixed ───────────────────────────────────────────────────
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

  /// Asks the LLM for a playlist name given genre + vibe context.
  /// Returns empty string on failure (caller falls back to algo name).
  Future<String> _generateAiPlaylistName(String genre, String vibe) async {
    if (!_modelAvailable || !_modelLoaded || _llama == null || !_isAiEnabled) return '';

    final vibeHint = vibe.isNotEmpty ? ' with a $vibe feeling' : '';
    final instruction =
        'Give one English word as a creative name for a $genre playlist$vibeHint. '
        'The word must evoke the mood, not describe it literally. '
        'Output only the single word, nothing else.';
    final prompt = _wrapPrompt(instruction, 'Name:');

    try {
      if (!_modelLoaded || _llama == null) return '';
      final stream = _llama!.generate(prompt: prompt, maxTokens: 8);
      String response = '';
      await for (final token in stream) {
        if (!_modelLoaded || _llama == null) break;
        response += token;
        generationProgress.value++;
      }
      return response.isNotEmpty ? _cleanPlaylistName(response) : '';
    } catch (_) {
      return '';
    }
  }

  Future<MapEntry<Song, String>?> generateNextVibeSong(Song currentSong) async {
    await _loadFuture;

    final db = DbService.instance;
    final allSongs =
        await db.songs.where().filter().isHiddenEqualTo(false).findAll();
    if (allSongs.isEmpty) return null;

    // Use vibe scoring to pick next song instead of pure shuffle
    final currentVibe = _songVibeTag(currentSong);
    var candidates =
        allSongs.where((s) => s.id != currentSong.id).toList();
    if (candidates.isEmpty) return null;

    final scored = _curateByScore(candidates, currentVibe, limit: 10);
    final nextSong = scored.isNotEmpty ? scored.first : candidates.first;

    String transition = "Up next: ${nextSong.title}";

    if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
      try {
        final instruction =
            'You are a DJ. Write one short sentence transitioning from "${currentSong.title}" to "${nextSong.title}". Be cool and brief.';
        final prompt = _wrapPrompt(instruction, 'Up next —');

        if (!_modelLoaded || _llama == null) {
          return MapEntry(nextSong, "Next up: ${nextSong.title}");
        }

        final stream = _llama!.generate(prompt: prompt, maxTokens: 40);
        String response = '';
        await for (final token in stream) {
          if (!_modelLoaded || _llama == null) break;
          response += token;
        }

        if (response.isNotEmpty) {
          transition = _cleanLlmResponse(response);
          print('[LLM] DJ Intro: $transition');
        }
      } catch (e) {
        print('[LLM] AI DJ error: $e');
      }
    } else {
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

  // ── Personality & Slide Insights ──────────────────────────────────────────

  /// Dedicated cleaner for playlist names: strictly 1 word, title-cased, alpha only.
  String _cleanPlaylistName(String text) {
    if (text.isEmpty) return '';

    String s = text
        .replaceAll(
            RegExp(r'\[\/?INST[\]\}]', caseSensitive: false), '')
        .replaceAll(
            RegExp(
                r'<s>|</s>|<start_of_turn>|<end_of_turn>',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(
                r'###\s*(INSTRUCTION|RESPONSE|END)[^:\n]*:?',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'Name\s*:', caseSensitive: false), '')
        .replaceAll(
            RegExp(
                r'(playlist|genre|word|name|music|creative|catchy|here|sure|certainly)[^a-zA-Z]*',
                caseSensitive: false),
            '')
        .trim();

    final firstLine =
        s.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');

    final words = firstLine.trim().split(RegExp(r'\s+'));
    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (clean.length >= 3 && !_isJunkWord(clean.toLowerCase())) {
        return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
      }
    }
    return '';
  }

  bool _isJunkWord(String w) {
    const junk = {
      'the', 'and', 'for', 'that', 'this', 'with', 'from', 'just', 'only',
      'here', 'sure', 'okay', 'well', 'yes', 'out', 'one', 'new'
    };
    return junk.contains(w);
  }

  /// Cleans general LLM response — used for recaps, insights, DJ intros.
  String _cleanLlmResponse(String text, {bool isTitle = false}) {
    if (text.isEmpty) return '';

    String scrubbed = text
        .replaceAll(
            RegExp(r'\[\/?INST[\]\}]', caseSensitive: false), '')
        .replaceAll(
            RegExp(
                r'<s>|</s>|<start_of_turn>|<end_of_turn>',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(
                r'###\s*(INSTRUCTION|RESPONSE|END)[^:\n]*:?',
                caseSensitive: false),
            '')
        .trim();

    final lines = scrubbed.split('\n');
    String result = '';

    for (var line in lines) {
      String l = line.trim();
      if (l.isEmpty) continue;

      while (l.startsWith(':') || l.startsWith('-') || l.startsWith(' ')) {
        l = l.substring(1).trim();
      }

      final low = l.toLowerCase();
      if (low.contains('playlist should') ||
          low.contains('style should') ||
          low.contains('based on your')) continue;
      if (low.contains('here is') ||
          low.contains('here\'s') ||
          low.contains('sure, i can')) continue;
      if (low.contains('certainly') ||
          low.contains('submission') ||
          low.contains('instruction')) continue;
      if (low.contains('write a short') ||
          low.contains('create a new word') ||
          low.contains('return only')) continue;
      if (low.contains('give one') ||
          low.contains('single english') ||
          low.contains('output only')) continue;
      if (low.contains('top genre:') ||
          low.contains('peak hour:') ||
          low.contains('top artist:') ||
          low.contains('top song:')) continue;
      if (low.contains('playlist name:') ||
          low.contains('name:') ||
          low.contains('response:')) continue;
      if (low.startsWith('user:') ||
          low.startsWith('assistant:') ||
          low.startsWith('system:') ||
          low.startsWith('model:')) continue;
      if (low.contains('<start_of_turn>') ||
          low.contains('<end_of_turn>')) continue;

      if (isTitle) {
        final words = l.split(RegExp(r'\s+'));
        if (words.isNotEmpty) {
          final first = words.first.replaceAll(RegExp(r'[^a-zA-Z]'), '');
          if (first.length < 2 ||
              first.toLowerCase() == 'playlist' ||
              first.toLowerCase() == 'name') {
            if (words.length > 1) {
              l = words.skip(1).join(' ');
            } else {
              continue;
            }
          }
        }
        l = l.split(' ').take(3).join(' ');
      }

      result = l;
      break;
    }

    if (result.isEmpty) result = scrubbed.split('\n').first.trim();

    result = result.replaceAll('"', '').replaceAll('\'', '');
    if (result.endsWith(':') || result.endsWith('.')) {
      if (result.split(' ').length < 5) {
        result = result.substring(0, result.length - 1);
      }
    }

    return result;
  }

  // ── PERSONALITY TITLE ─────────────────────────────────────────────────────
  //
  // New flow:
  //   1. LLM generates a 2-word title evoked by the listener's actual
  //      genre + loyalty + time-vibe (not just genre alone)
  //   2. If LLM fails or produces junk → genre-mapped algo fallback
  //
  // Prompt is phrased as a fill-in ("The ___") so tiny models don't pivot
  // to writing a sentence instead of a noun phrase.

  /// Generate a unique personality title (e.g. "The Velvet Midnight")
  Future<String> generateListeningPersonality(WrappedReport report) async {
    await _loadFuture;
    final topGenre = _getTopGenre(report);
    final timeVibe = _peakHourVibe(report.peakHour);
    final loyalty = report.topArtistPlays > 50
        ? 'obsessive'
        : report.topArtistPlays > 20
            ? 'devoted'
            : 'casual';

    if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
      try {
        if (!_modelLoaded || _llama == null) return _personalityFallback(topGenre);

        // Richer context → more unique output; still fill-in to avoid prose
        final instruction =
            'Create a 2-word music listener personality title. '
            'The listener is a $loyalty $topGenre fan and a $timeVibe type. '
            'Examples: "Velvet Midnight", "Static Dreamer", "Neon Specter". '
            'Output only the 2 words, no punctuation, no explanation.';
        final prompt = _wrapPrompt(instruction, 'The');

        generationProgress.value = 0;
        final stream = _llama!.generate(prompt: prompt, maxTokens: 12);
        String response = '';
        await for (final token in stream) {
          if (!_modelLoaded || _llama == null) break;
          response += token;
          generationProgress.value++;
        }
        if (response.isNotEmpty) {
          final cleaned = _cleanLlmResponse(response, isTitle: true);
          if (cleaned.length > 3) return 'The $cleaned';
        }
      } catch (_) {}
    }

    return _personalityFallback(topGenre);
  }

  /// Algo fallback map for personality titles.
  String _personalityFallback(String topGenre) {
    if (topGenre.contains('Lo-fi') || topGenre.contains('Chill')) return 'The Tranquil Soul';
    if (topGenre.contains('Rock') || topGenre.contains('Metal')) return 'The Sonic Rebel';
    if (topGenre.contains('Pop')) return 'The Chart Chaser';
    if (topGenre.contains('Hip Hop') || topGenre.contains('Rap')) return 'The Frequency Rider';
    if (topGenre.contains('Jazz')) return 'The Midnight Wanderer';
    if (topGenre.contains('Electronic')) return 'The Neon Nomad';
    return 'The Melodic Nomad';
  }

  /// Generate a catchy insight about peak listening time
  Future<String> generateTimeInsight(int peakHour, int totalMinutes) async {
    await _loadFuture;
    final timeStr = peakHour >= 12
        ? '${peakHour == 12 ? 12 : peakHour - 12} PM'
        : '${peakHour == 0 ? 12 : peakHour} AM';

    if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
      try {
        if (!_modelLoaded || _llama == null) {
          return '$timeStr — the perfect hour for music.';
        }

        final instruction =
            'Write one short witty sentence about listening to music at $timeStr. Max 12 words. No quotes.';
        final prompt = _wrapPrompt(instruction, '$timeStr —');

        final stream = _llama!.generate(prompt: prompt, maxTokens: 24);
        String response = '';
        await for (final token in stream) {
          if (!_modelLoaded || _llama == null) break;
          response += token;
        }
        if (response.isNotEmpty) {
          final c = _cleanLlmResponse(response);
          if (c.length > 5) return '$timeStr — $c';
        }
      } catch (_) {}
    }

    if (peakHour >= 22 || peakHour <= 4) return '$timeStr — Late nights hit different.';
    if (peakHour >= 7 && peakHour <= 10) return '$timeStr — Fueling your morning with pure sound.';
    return '$timeStr — When the world fades and the music takes over.';
  }

  /// Generate a witty remark about the top artist
  Future<String> generateArtistInsight(String artist, int playCount) async {
    await _loadFuture;

    if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
      try {
        if (!_modelLoaded || _llama == null) {
          return '$artist was there for you. Every single time.';
        }

        final instruction =
            'Write one cheeky 10-word sentence about $artist being my most played artist. No quotes.';
        final prompt = _wrapPrompt(instruction, '$artist');

        final stream = _llama!.generate(prompt: prompt, maxTokens: 24);
        String response = '';
        await for (final token in stream) {
          if (!_modelLoaded || _llama == null) break;
          response += token;
        }
        if (response.isNotEmpty) {
          final c = _cleanLlmResponse(response);
          if (c.length > 5) return c;
        }
      } catch (_) {}
    }

    return '$artist was there for you. All $playCount times.';
  }

  /// Generate a witty remark about total minutes
  Future<String> generateMinutesInsight(int minutes) async {
    await _loadFuture;
    final hours = (minutes / 60).toStringAsFixed(1);

    if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
      try {
        if (!_modelLoaded || _llama == null) {
          return 'That\'s $hours hours. Your headphones deserve a raise.';
        }

        final instruction =
            'Write one funny 12-word sentence about listening to $hours hours of music. No quotes.';
        final prompt = _wrapPrompt(instruction, 'That\'s');

        final stream = _llama!.generate(prompt: prompt, maxTokens: 28);
        String response = '';
        await for (final token in stream) {
          if (!_modelLoaded || _llama == null) break;
          response += token;
        }
        if (response.isNotEmpty) {
          final c = _cleanLlmResponse(response);
          if (c.length > 5) return c;
        }
      } catch (_) {}
    }

    return 'That\'s $hours hours. We\'re not judging. (Okay, maybe a little).';
  }

  /// Generate a witty caption for the top song
  Future<String> generateSongInsight(String song) async {
    await _loadFuture;

    if (_modelAvailable && _modelLoaded && _llama != null && _isAiEnabled) {
      try {
        if (!_modelLoaded || _llama == null) return 'Your soundtrack, on loop.';

        final instruction =
            'Write one punchy 8-word caption for "$song" being my most played song. No quotes.';
        final prompt = _wrapPrompt(instruction, '"$song" —');

        final stream = _llama!.generate(prompt: prompt, maxTokens: 20);
        String response = '';
        await for (final token in stream) {
          if (!_modelLoaded || _llama == null) break;
          response += token;
        }
        if (response.isNotEmpty) {
          final c = _cleanLlmResponse(response, isTitle: true);
          if (c.length > 5) return c;
        }
      } catch (_) {}
    }

    return 'Your soundtrack, on loop.';
  }

  // ── Local template-based fallback ─────────────────────────────────────────

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

    final index = (report.totalMinutes + report.topArtistPlays) % templates.length;
    return templates[index];
  }

  String _getTopGenre(WrappedReport report) {
    try {
      final Map<String, dynamic> genres = jsonDecode(report.genreJsonStr);
      if (genres.isEmpty) return 'Unknown';
      var top = genres.entries.first;
      for (var e in genres.entries) {
        if ((e.value as num) > (top.value as num)) top = e;
      }
      return top.key;
    } catch (_) {
      return 'Unknown';
    }
  }
}