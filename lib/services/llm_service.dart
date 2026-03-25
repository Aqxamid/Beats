// services/llm_service.dart
// Local on-device text generator for Wrapped recaps.
// Attempts to use fllama (TinyLlama GGUF) if a model file exists on-device.
// Falls back to smart template-based generation (no external API calls).
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import '../models/wrapped_report.dart';

class LlmService {
  LlmService._();
  static final LlmService instance = LlmService._();

  static const _apiKeyPref = 'llm_api_key';
  static const _modelPathPref = 'llm_model_path';

  String _cachedApiKey = '';
  String _modelPath = '';
  bool _modelAvailable = false;
  Llama? _llama;

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

    if (!await File(path).exists()) {
      _modelAvailable = false;
      return;
    }

    try {
      // llama_cpp_dart 0.1.2 constructor: Llama(modelPath, modelParams, [contextParams])
      _llama = Llama(path, ModelParams(), ContextParams());
      _modelAvailable = _llama != null;
      _modelPath = path;
    } catch (e) {
      _modelAvailable = false;
    }
  }

  /// Generate a Wrapped recap paragraph for [report].
  /// Tries the real model first, falls back to templates.
  Future<String> generateWrappedRecap(WrappedReport report) async {
    if (_modelAvailable && _llama != null) {
      try {
        final prompt = _buildPrompt(report);
        // Using common prompt template for chat models
        final fullPrompt = "<s>[INST] $prompt [/INST]";
        
        // Correct 0.1.2+1 usage: setPrompt then generate
        _llama!.setPrompt(fullPrompt);
        final response = await _llama!.generateCompleteText(maxTokens: 128);

        if (response.isNotEmpty) return response.trim();
      } catch (e) {
        // Fallback to templates below
      }
    }

    try {
      return _generateLocal(report);
    } catch (e) {
      return 'You had an amazing ${report.periodLabel}! '
          '${report.topArtist} was your top artist with ${report.topArtistPlays} plays.';
    }
  }

  String _buildPrompt(WrappedReport report) {
    return "Write a short, punchy, personality-driven 2-sentence summary of my music taste for this ${report.periodLabel}. "
        "Top artist: ${report.topArtist} (${report.topArtistPlays} plays). "
        "Total minutes: ${report.totalMinutes}. "
        "Peak hour: ${report.peakHourLabel}. "
        "Personality type: ${report.personalityType}. "
        "Listening streak: ${report.streakDays} days. "
        "Be casual and use modern lingo.";
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
