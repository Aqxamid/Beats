// screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/llm_service.dart';
import '../../services/lyrics_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasApiKey = false;
  String _modelFilename = 'None';
  bool _isModelLoading = false;
  bool _isPickingModel = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  void _checkApiKey() async {
    final key = await LlmService.instance.currentApiKey;
    final modelPath = await LlmService.instance.currentModelPath;
    setState(() {
      _hasApiKey = key.isNotEmpty;
      _modelFilename = modelPath.split('/').last.split('\\').last;
      if (_modelFilename.isEmpty) _modelFilename = 'None';
    });
  }

  void _pickModel() async {
    if (_isPickingModel) return;
    
    setState(() => _isPickingModel = true);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // GGUF files often don't have a standard mime type
      );
      
      if (!mounted || result == null || result.files.single.path == null) {
        if (mounted) setState(() => _isPickingModel = false);
        return;
      }

      final path = result.files.single.path!;
      if (!path.toLowerCase().endsWith('.gguf')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid .gguf model file.')),
          );
          setState(() => _isPickingModel = false);
        }
        return;
      }

      setState(() => _isModelLoading = true);
      try {
        await LlmService.instance.loadModel(path);
        if (!mounted) return;
        
        await LlmService.instance.updateModelPath(path);
        _checkApiKey();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Model loaded successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          String message = 'Failed to load model: $e';
          if (e.toString().contains('ENOSPC')) {
            message = 'Error: Not enough storage space on device to import model.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isModelLoading = false;
            _isPickingModel = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPickingModel = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Picker error: $e')),
        );
      }
    }
  }

  void _showApiKeyDialog() async {
    final controller = TextEditingController(text: await LlmService.instance.currentApiKey);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Gemini API Key', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter API Key',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: BeatSpillTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await LlmService.instance.updateApiKey(controller.text.trim());
              _checkApiKey();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: BeatSpillTheme.green)),
          ),
        ],
      ),
    );
  }

  void _showLyricsDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool started = false;
        int current = 0;
        int total = 0;
        bool done = false;

        return StatefulBuilder(builder: (context, setDialogState) {
          if (!started) {
            started = true;
            LyricsService.instance.downloadAllMissingLyrics(
              onProgress: (c, t) {
                if (ctx.mounted) {
                  setDialogState(() {
                    current = c;
                    total = t;
                    if (t > 0 && c >= t) done = true;
                  });
                }
              },
            ).then((_) {
              if (ctx.mounted) {
                setDialogState(() => done = true);
              }
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF282828),
            title: const Text('Downloading Lyrics', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (total > 0) ...[
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : current / total,
                    backgroundColor: Colors.white24,
                    color: BeatSpillTheme.green,
                  ),
                  const SizedBox(height: 16),
                  Text('$current / $total downloaded', style: const TextStyle(color: Colors.white70)),
                ] else if (done) ...[
                  const Text('All lyrics are up to date!', style: TextStyle(color: Colors.white70)),
                ] else ...[
                  const CircularProgressIndicator(color: BeatSpillTheme.green),
                  const SizedBox(height: 16),
                  const Text('Scanning library...', style: TextStyle(color: Colors.white70)),
                ],
              ],
            ),
            actions: [
              if (done || total == 0)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: BeatSpillTheme.green)),
                ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Profile tile ──────────────────────────
          if (false) // Hidden for now
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E8B57),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            title: const Text('maya'),
            subtitle: const Text('View Profile'),
            trailing: const Icon(Icons.chevron_right, color: BeatSpillTheme.textSecondary),
            onTap: () {},
          ),
          // const Divider(height: 1),

          // ── Standard settings ─────────────────────
          if (false) // Hidden for now
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
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wrapped Cadence is currently locked to Monthly for stability.')),
              );
            },
          ),
          if (false) // Hidden for now
          _SettingsTile(
            label: 'Cloud Sync',
            trailing: const Text('On',
                style: TextStyle(color: BeatSpillTheme.green, fontSize: 13)),
          ),
          _SettingsTile(
            label: 'AI Personality & Recap (LMM)',
            trailing: Text(_hasApiKey ? 'Ready' : 'Template Mode',
                style: TextStyle(
                    color: _hasApiKey ? BeatSpillTheme.green : BeatSpillTheme.textSecondary,
                    fontSize: 13)),
            onTap: _showApiKeyDialog,
          ),
          _SettingsTile(
            label: 'Local AI Model (.gguf)',
            trailing: _isModelLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BeatSpillTheme.green),
                  )
                : Text(_modelFilename,
                    style: TextStyle(
                        color: _modelFilename == 'None'
                            ? BeatSpillTheme.textSecondary
                            : BeatSpillTheme.green,
                        fontSize: 13)),
            onTap: _pickModel,
          ),
          _SettingsTile(
            label: 'Lyrics Source',
            trailing: const Text('lrclib.net',
                style: TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 13)),
          ),
          _SettingsTile(
            label: 'Download Missing Lyrics',
            onTap: () => _showLyricsDownloadDialog(context),
          ),
          _SettingsTile(
            label: 'About',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'BeatSpill',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.music_note, color: BeatSpillTheme.green),
                children: [
                  const Text('A simple project of mine : Allen Ronn Parado'),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: BeatSpillTheme.textSecondary),
      onTap: onTap ?? () {},
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
