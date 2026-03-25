// services/wrapped_generator.dart
// Orchestrates the full Wrapped generation pipeline:
//   1. Compute stats from Isar (StatsService)
//   2. Generate LLM recap (LlmService)
//   3. Save WrappedReport to Isar
//   4. Return report for slideshow display
import 'package:isar/isar.dart';
import '../models/wrapped_report.dart';
import 'db_service.dart';
import 'stats_service.dart';
import 'llm_service.dart';

class WrappedGenerator {
  WrappedGenerator._();
  static final WrappedGenerator instance = WrappedGenerator._();

  final _stats = StatsService.instance;
  final _llm   = LlmService.instance;
  final _db    = DbService.instance;

  /// Generate a monthly Wrapped for [year]/[month].
  /// [onProgress] receives 0.0–1.0 as work completes.
  Future<WrappedReport> generate(
    int year,
    int month, {
    void Function(double progress, String label)? onProgress,
  }) async {
    onProgress?.call(0.1, 'Crunching your stats…');

    // ── Step 1: Aggregate stats ────────────────────
    final report = await _stats.buildMonthlyReport(year, month);
    onProgress?.call(0.5, 'Building your story…');

    // ── Step 2: LLM recap ──────────────────────────
    final recap = await _llm.generateWrappedRecap(report);
    report.llmRecap = recap;
    onProgress?.call(0.85, 'Putting it all together…');

    // ── Step 3: Persist to Isar ────────────────────
    await _db.isar.writeTxn(() async {
      await _db.wrappedReports.put(report);
    });

    onProgress?.call(1.0, 'Done!');
    return report;
  }

  /// Fetch all past reports (newest first) for the history list.
  Future<List<WrappedReport>> history() async {
    final reports = await _db.wrappedReports
        .where()
        .findAll();
    reports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return reports;
  }
}
