// screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Profile tile ──────────────────────────
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E8B57),
              child: const Text('🎵', style: TextStyle(fontSize: 18)),
            ),
            title: const Text('maya'),
            subtitle: const Text('View Profile'),
            trailing: const Icon(Icons.chevron_right, color: BeatSpillTheme.textSecondary),
            onTap: () {},
          ),
          const Divider(height: 1),

          // ── Standard settings ─────────────────────
          ...[
            'Account',
            'Playback',
            'Audio Quality',
            'Storage & Downloads',
            'Local Files',
          ].map((label) => _SettingsTile(label: label)),

          const _SectionDivider(label: 'BeatSpill'),

          // ── BeatSpill-specific settings ───────────
          _SettingsTile(
            label: 'Wrapped Cadence',
            trailing: const Text('Monthly',
                style: TextStyle(color: BeatSpillTheme.green, fontSize: 13)),
          ),
          _SettingsTile(
            label: 'Cloud Sync',
            trailing: const Text('On',
                style: TextStyle(color: BeatSpillTheme.green, fontSize: 13)),
          ),
          _SettingsTile(
            label: 'LLM Model',
            trailing: const Text('Gemma 3 1B',
                style: TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 13)),
          ),
          _SettingsTile(
            label: 'Lyrics Source',
            trailing: const Text('lrclib.net',
                style: TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 13)),
          ),
          _SettingsTile(label: 'About'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SettingsTile({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: BeatSpillTheme.textSecondary),
      onTap: () {},
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: BeatSpillTheme.textMuted)),
    );
  }
}
