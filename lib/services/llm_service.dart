// services/llm_service.dart
// On-device LLM wrapper for Gemma 3 1B via MediaPipe Flutter plugin.
//
// WIRING STATUS: Stub — returns a mock recap until the MediaPipe
// flutter_mediapipe_core / google_mediapipe_genai plugin is added
// and the model asset is downloaded to app storage.
//
// HOW TO WIRE (next steps):
//   1. Add mediapipe_genai to pubspec.yaml when stable on pub.dev
//      OR use method channel to call native MediaPipe LlmInference.
//   2. Download gemma3-1b-it-int4.task to getApplicationSupportDirectory()
//      on first launch (show a one-time download progress UI).
//   3. Replace _generateMock() calls with real inference calls below.
import '../models/wrapped_report.dart';

class LlmService {
  LlmService._();
  static final LlmService instance = LlmService._();

  bool _modelLoaded = false;

  // ignore: unused_field
  dynamic _llmInference; // will be MediaPipe LlmInference instance

  /// Returns true if model file exists and inference is ready.
  Future<bool> get isReady async => _modelLoaded;

  /// Load the model from disk. Call once after app init.
  Future<void> loadModel(String modelPath) async {
    // TODO: initialise MediaPipe LlmInference here
    // _llmInference = await LlmInference.createFromOptions(
    //   LlmInferenceOptions(modelPath: modelPath, maxTokens: 512),
    // );
    _modelLoaded = true; // remove once real init is in place
  }

  /// Generate a Wrapped recap paragraph for [report].
  /// Calls the on-device model if ready, otherwise returns a mock.
  Future<String> generateWrappedRecap(WrappedReport report) async {
    if (!_modelLoaded) return _generateMock(report);

    final prompt = _buildPrompt(report);

    // TODO: replace with real inference:
    // final response = await _llmInference.generateResponse(prompt);
    // return response.trim();

    return _generateMock(report); // stub until model is wired
  }

  // ── Prompt construction ──────────────────────────────────────
  //
  // System: bakes in the Wrapped tone (witty, warm, roast-y, punchy).
  // User:   provides structured stats so the model just tone-matches.

  String _buildPrompt(WrappedReport report) {
    return '''<start_of_turn>system
You write Spotify Wrapped-style music recaps. Be witty, a little roast-y, self-aware, and warm. Use short punchy sentences. Never be mean. Max 4 sentences.<end_of_turn>
<start_of_turn>user
User: maya. Period: ${report.periodLabel}. Top artist: ${report.topArtist} (${report.topArtistPlays} plays). Top song: ${report.topSong}. Peak hour: ${report.peakHourLabel}. Streak: ${report.streakDays} days. Skip rate: ${(report.skipRate * 100).round()}%. Personality: ${report.personalityType}. Write their recap.<end_of_turn>
<start_of_turn>model
''';
  }

  // ── Mock (used until model is integrated) ────────────────────
  String _generateMock(WrappedReport report) {
    return 'You had a cinematic ${report.periodLabel}. '
        '${report.topArtist} carried you through the best and worst moments. '
        'Your ${report.personalityType} energy peaked at ${report.peakHourLabel} — '
        "and honestly? We stan the dedication.";
  }
}
