// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeatSpillTheme.background,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Avatar ────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF2E8B57),
                  child: const Text('🎵', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 10),
                const Text('maya',
                    style: TextStyle(
                        color: BeatSpillTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Stats row ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _StatItem('23', 'Playlists'),
              _StatItem('1,847', 'Minutes'),
              _StatItemGreen('7d 🔥', 'Streak'),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),

          // ── Playlists section ─────────────────────
          const SizedBox(height: 12),
          const Text('Playlists',
              style: TextStyle(
                  color: BeatSpillTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 10),
          _PlaylistRow('Shazam', '7 songs', const Color(0xFF1A3A5C)),
          _PlaylistRow('Roadtrip', '4 songs', const Color(0xFF2D6A4F)),
          const SizedBox(height: 8),
          const Text('See all playlists ›',
              style: TextStyle(
                  color: BeatSpillTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: BeatSpillTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: BeatSpillTheme.textMuted,
                fontSize: 9,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _StatItemGreen extends _StatItem {
  const _StatItemGreen(super.value, super.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: BeatSpillTheme.green,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: BeatSpillTheme.textMuted,
                fontSize: 9,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color color;
  const _PlaylistRow(this.name, this.subtitle, this.color);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(name,
          style: const TextStyle(
              color: BeatSpillTheme.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: BeatSpillTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right,
          color: BeatSpillTheme.textSecondary),
      onTap: () {},
    );
  }
}
