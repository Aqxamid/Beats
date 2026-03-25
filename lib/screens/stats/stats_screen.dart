// screens/stats/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/stats_provider.dart';
import '../../services/wrapped_generator.dart';
import '../wrapped/wrapped_slideshow_screen.dart';
import '../../widgets/mini_player.dart';

// ── Period toggle enum ────────────────────────────────────────

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final minutes = ref.watch(minutesProvider);
    final songs = ref.watch(songCountProvider);
    final streak = ref.watch(streakProvider);
    final skipRate = ref.watch(skipRateProvider);
    final topArtists = ref.watch(topArtistsProvider);
    final heatmap = ref.watch(heatmapProvider);
    final genres = ref.watch(genreBreakdownProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            children: [
              const SizedBox(height: 16),
            // ── Header + period toggle ─────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Stats',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 20)),
                _PeriodToggle(
                  current: ref.watch(statsPeriodProvider),
                  onChanged: (p) => ref.read(statsPeriodProvider.notifier).state = p,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Wrapped trigger card ───────────────────
            _WrappedTriggerCard(
              generating: _generating,
              onTap: _generateWrapped,
            ),
            const SizedBox(height: 16),

            // ── 4 stat cards ──────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  label: 'Minutes',
                  value: minutes.when(
                    data: (v) => _fmt(v),
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  icon: Icons.headphones,
                  color: BeatSpillTheme.purple,
                ),
                _StatCard(
                  label: 'Songs',
                  value: songs.when(
                    data: (v) => _fmt(v),
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  icon: Icons.music_note,
                  color: BeatSpillTheme.green,
                ),
                _StatCard(
                  label: 'Streak',
                  value: streak.when(
                    data: (v) => '$v d 🔥',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  icon: Icons.local_fire_department,
                  color: BeatSpillTheme.orange,
                ),
                _StatCard(
                  label: 'Skip Rate',
                  value: skipRate.when(
                    data: (v) => '${(v * 100).round()}%',
                    loading: () => '…',
                    error: (_, __) => '—',
                  ),
                  icon: Icons.skip_next,
                  color: BeatSpillTheme.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Top artists ───────────────────────────
            Text('Top artists this month',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            topArtists.when(
              data: (artists) {
                if (artists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Play some songs to see your top artists',
                        style: TextStyle(color: BeatSpillTheme.textMuted)),
                  );
                }
                final maxVal = artists.first.value;
                return Column(
                  children: artists
                      .map((a) => _BarRow(
                            label: a.key,
                            value: a.value,
                            max: maxVal,
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading data'),
            ),
            const SizedBox(height: 20),

            // ── Heatmap ───────────────────────────────
            Text('When you listen',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            heatmap.when(
              data: (matrix) {
                // Condense 7×24 into 3 rows: AM (6-12), PM (12-18), Night (18-6)
                final condensed = _condenseHeatmap(matrix);
                return _HeatmapWidget(matrix: condensed);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading data'),
            ),
            const SizedBox(height: 20),

            // ── Genre breakdown ───────────────────────
            Text('Genre breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            genres.when(
              data: (genreMap) {
                if (genreMap.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No genre data yet',
                        style: TextStyle(color: BeatSpillTheme.textMuted)),
                  );
                }
                final total =
                    genreMap.values.fold<int>(0, (sum, v) => sum + v);
                final sorted = genreMap.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final colors = [
                  BeatSpillTheme.green,
                  BeatSpillTheme.purple,
                  BeatSpillTheme.red,
                  BeatSpillTheme.orange,
                  BeatSpillTheme.blue,
                ];
                return Column(
                  children: sorted.asMap().entries.map((entry) {
                    final pct =
                        total > 0 ? entry.value.value / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BarRow(
                        label: entry.value.key,
                        value: (pct * 100).round(),
                        max: 100,
                        color: colors[entry.key % colors.length],
                        suffix: '${(pct * 100).round()}%',
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading data'),
            ),
            const SizedBox(height: 100), // Space for miniplayer
          ],
        ),
      ),
      const MiniPlayer(),
    ],
  );
}

  List<List<int>> _condenseHeatmap(List<List<int>> full) {
    // full is [dayOfWeek(7)][hour(24)]
    // Condense into [3 rows: AM/PM/Night][7 days]
    final condensed = List.generate(3, (_) => List.filled(7, 0));
    for (int day = 0; day < 7 && day < full.length; day++) {
      for (int h = 0; h < 24 && h < full[day].length; h++) {
        final row = h < 12 ? 0 : (h < 18 ? 1 : 2);
        condensed[row][day] += full[day][h];
      }
    }
    // Normalize to 0–3 intensity
    int maxVal = 1;
    for (final row in condensed) {
      for (final v in row) {
        if (v > maxVal) maxVal = v;
      }
    }
    return condensed
        .map((row) => row.map((v) => (v * 3 / maxVal).round().clamp(0, 3)).toList())
        .toList();
  }

  Future<void> _generateWrapped() async {
    setState(() => _generating = true);

    final now = DateTime.now();
    try {
      final report = await WrappedGenerator.instance.generate(
        now.year,
        now.month,
        onProgress: (progress, label) {
          // Could show progress in UI, but slideshow loads quickly
        },
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WrappedSlideshowScreen(report: report),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _fmt(int n) => n >= 1000
      ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'
      : '$n';
}

// ── Wrapped trigger card ──────────────────────────────────────
class _WrappedTriggerCard extends StatelessWidget {
  final bool generating;
  final VoidCallback onTap;
  const _WrappedTriggerCard({required this.generating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BeatSpillTheme.green, BeatSpillTheme.greenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Wrapped',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  )),
          const SizedBox(height: 4),
          Text('${months[now.month]} ends in $daysLeft days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: generating ? null : onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Generate now ↗',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single stat card ──────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BeatSpillTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10, color: BeatSpillTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Horizontal bar row ────────────────────────────────────────
class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final String? suffix;
  const _BarRow(
      {required this.label,
      required this.value,
      required this.max,
      this.color = BeatSpillTheme.green,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12)),
            Text(suffix ?? '$value',
                style: const TextStyle(
                    color: BeatSpillTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: max > 0 ? value / max : 0,
            backgroundColor: BeatSpillTheme.surfaceAlt,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Listening heatmap widget ──────────────────────────────────
class _HeatmapWidget extends StatelessWidget {
  final List<List<int>> matrix; // [row][day]
  const _HeatmapWidget({required this.matrix});

  Color _cellColor(int intensity) {
    switch (intensity) {
      case 0: return BeatSpillTheme.surfaceAlt;
      case 1: return const Color(0xFF1A3D21);
      case 2: return const Color(0xFF145A32);
      default: return BeatSpillTheme.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const rowLabels = ['AM', 'PM', 'Night'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        Row(
          children: [
            const SizedBox(width: 36),
            ...days.map((d) => Expanded(
                  child: Text(d,
                      style: const TextStyle(
                          color: BeatSpillTheme.textMuted, fontSize: 9),
                      textAlign: TextAlign.center),
                )),
          ],
        ),
        const SizedBox(height: 4),
        // Rows
        ...matrix.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(rowLabels[entry.key],
                        style: const TextStyle(
                            color: BeatSpillTheme.textMuted, fontSize: 9)),
                  ),
                  ...entry.value.map((intensity) => Expanded(
                        child: Container(
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: _cellColor(intensity),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Period toggle ─────────────────────────────────────────────
class _PeriodToggle extends StatelessWidget {
  final StatsPeriod current;
  final ValueChanged<StatsPeriod> onChanged;
  const _PeriodToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const periods = [
      (StatsPeriod.week, 'W'),
      (StatsPeriod.month, 'M'),
      (StatsPeriod.quarter, 'Q'),
      (StatsPeriod.allTime, 'All'),
    ];

    return Row(
      children: periods.map((p) {
        final active = p.$1 == current;
        return GestureDetector(
          onTap: () => onChanged(p.$1),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active ? BeatSpillTheme.green : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: active
                  ? null
                  : Border.all(color: BeatSpillTheme.textMuted),
            ),
            child: Text(p.$2,
                style: TextStyle(
                    color: active ? Colors.black : BeatSpillTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ),
        );
      }).toList(),
    );
  }
}
