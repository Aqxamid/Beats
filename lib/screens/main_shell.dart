// screens/main_shell.dart
// Root scaffold with persistent bottom nav: Home | Search | Stats | Library
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

import '../theme/app_theme.dart';
import 'library/home_screen.dart';
import 'library/search_screen.dart';
import 'stats/stats_screen.dart';
import 'library/library_screen.dart';
import '../widgets/global_ai_status_indicator.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    StatsScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(shellTabIndexProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
            const GlobalAiStatusIndicator(),
          ],
        ),
      ),
      bottomNavigationBar: _BopNavBar(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(shellTabIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ── Custom bottom nav ─────────────────────────────────────────
class _BopNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BopNavBar(
      {required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home, Icons.home_outlined, 'Home'),
      (Icons.search, Icons.search_outlined, 'Search'),
      (Icons.bar_chart, Icons.bar_chart_outlined, 'Stats'),
      (Icons.library_music, Icons.library_music_outlined, 'Library'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: BopTheme.surfaceAlt, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.$1 : item.$2,
                        color: isActive
                            ? BopTheme.textPrimary
                            : BopTheme.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive
                              ? BopTheme.textPrimary
                              : BopTheme.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
