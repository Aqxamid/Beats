// screens/profile/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/llm_service.dart';
import '../../services/lyrics_service.dart';
import '../../services/metadata_service.dart';
import '../../services/db_service.dart';
import '../../models/song.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasApiKey = false;
  String _modelFilename = 'None';
  bool _isModelLoading = false;
  bool _isPickingModel = false;

  String _username = 'Guest';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      String? path = prefs.getString('avatar_path');
      // If the file was in cache and got deleted, clear it to prevent errors
      if (path != null && !File(path).existsSync()) {
        await prefs.remove('avatar_path');
        path = null;
      }

      setState(() {
        _username = prefs.getString('username') ?? 'Guest';
        _avatarPath = path;
      });
    }
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
          String message = e.toString().replaceAll('Exception: ', '');
          if (message.contains('ENOSPC')) {
            message = 'Error: Not enough storage space on device to import model.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
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
            child: const Text('Cancel', style: TextStyle(color: BopTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await LlmService.instance.updateApiKey(controller.text.trim());
              _checkApiKey();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: BopTheme.green)),
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
                    color: BopTheme.green,
                  ),
                  const SizedBox(height: 16),
                  Text('$current / $total downloaded', style: const TextStyle(color: Colors.white70)),
                ] else if (done) ...[
                  const Text('All lyrics are up to date!', style: TextStyle(color: Colors.white70)),
                ] else ...[
                  const CircularProgressIndicator(color: BopTheme.green),
                  const SizedBox(height: 16),
                  const Text('Scanning library...', style: TextStyle(color: Colors.white70)),
                ],
              ],
            ),
            actions: [
              if (done || total == 0)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: BopTheme.green)),
                ),
            ],
          );
        });
      },
    );
  }

  void _showEditProfileDialog() async {
    final controller = TextEditingController(text: _username);
    String? tempAvatar = _avatarPath;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    withData: true,
                  );
                  if (result != null) {
                    final file = result.files.single;
                    if (file.path != null) {
                      setDialogState(() => tempAvatar = file.path);
                    } else if (file.bytes != null) {
                      final tempDir = await getTemporaryDirectory();
                      final tempFile = File('${tempDir.path}/avatar_temp_${DateTime.now().millisecondsSinceEpoch}.png');
                      await tempFile.writeAsBytes(file.bytes!);
                      setDialogState(() => tempAvatar = tempFile.path);
                    }
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: BopTheme.surfaceAlt,
                  backgroundImage: tempAvatar != null ? FileImage(File(tempAvatar!)) : null,
                  child: tempAvatar == null ? const Icon(Icons.add_a_photo, color: Colors.white54) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white54),
                  hintText: 'Enter your name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: BopTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final newName = controller.text.trim().isNotEmpty ? controller.text.trim() : 'Guest';
                await prefs.setString('username', newName);
                
                if (tempAvatar != null && tempAvatar != _avatarPath) {
                  try {
                    final docDir = await getApplicationDocumentsDirectory();
                    final savePath = '${docDir.path}/avatar_user.png';
                    final oldFile = File(savePath);
                    if (await oldFile.exists()) await oldFile.delete();
                    await File(tempAvatar!).copy(savePath);
                    await prefs.setString('avatar_path', savePath);
                  } catch (e) {
                    print('Error saving avatar: $e');
                  }
                }
                
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: BopTheme.green)),
            ),
          ],
        ),
      ),
    );
    _loadProfile();
  }

  Future<void> _fetchAllMissingMetadata() async {
    final songs = await DbService.instance.isar.songs.where().findAll();
    final missing = songs.where((s) => 
      MetadataService.instance.isArtistMissing(s.artist) || 
      MetadataService.instance.isAlbumMissing(s.album) || 
      MetadataService.instance.isGenreMissing(s.genre)
    ).toList();

    if (missing.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All songs already have metadata!')),
        );
      }
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Fetching Metadata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(color: BopTheme.green),
            const SizedBox(height: 16),
            Text('Processing ${missing.length} songs...'),
          ],
        ),
      ),
    );

    int count = 0;
    for (final song in missing) {
      try {
        await MetadataService.instance.fetchAndFillMetadata(song);
        count++;
        // Respect MusicBrainz rate limit (1 req/sec)
        await Future.delayed(const Duration(seconds: 1));
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully updated metadata for $count songs.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E8B57),
              backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
              child: _avatarPath == null ? const Icon(Icons.person, color: Colors.white, size: 18) : null,
            ),
            title: Text(_username),
            subtitle: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right, color: BopTheme.textSecondary),
            onTap: _showEditProfileDialog,
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

          const _SectionDivider(label: 'Bop'),
          const SizedBox(height: 12),
          // ── Bop-specific settings ───────────
          _SettingsTile(
            label: 'Wrapped Cadence',
            trailing: const Text('Monthly',
                style: TextStyle(color: BopTheme.green, fontSize: 13)),
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
                style: TextStyle(color: BopTheme.green, fontSize: 13)),
          ),
          _SettingsTile(
            label: 'AI Personality & Recap (LMM)',
            trailing: Text(_hasApiKey ? 'Ready' : 'Template Mode',
                style: TextStyle(
                    color: _hasApiKey ? BopTheme.green : BopTheme.textSecondary,
                    fontSize: 13)),
            onTap: _showApiKeyDialog,
          ),
          _SettingsTile(
            label: 'Local AI Model (.gguf)',
            subtitle: 'Requires GGUF format (e.g. TinyLlama-1.1B)',
            trailing: _isModelLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BopTheme.green),
                  )
                : Text(_modelFilename,
                    style: TextStyle(
                        color: _modelFilename == 'None'
                            ? BopTheme.textSecondary
                            : BopTheme.green,
                        fontSize: 13)),
            onTap: _pickModel,
          ),
          _SettingsTile(
            label: 'Lyrics Source',
            trailing: const Text('lrclib.net',
                style: TextStyle(color: BopTheme.textSecondary, fontSize: 13)),
          ),
          _SettingsTile(
            label: 'Download Missing Lyrics',
            onTap: () => _showLyricsDownloadDialog(context),
          ),
          _SettingsTile(
            label: 'Fetch All Missing Metadata',
            subtitle: 'Auto-fill artist, album, and genre tags',
            onTap: _fetchAllMissingMetadata,
          ),
          
          const _SectionDivider(label: 'Design & Feel'),
          SwitchListTile(
            title: const Text('Bop Bold Rendition', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Spotify-inspired high-contrast & abstract shapes (BETA)', style: TextStyle(fontSize: 11)),
            value: ref.watch(boldDesignProvider),
            activeColor: BopTheme.green,
            onChanged: (val) {
              ref.read(boldDesignProvider.notifier).toggle();
            },
          ),
          
          const _SectionDivider(label: 'Recap Preview (PREVIEW)'),
          SwitchListTile(
            title: const Text('Simulate November (Teaser)', style: TextStyle(fontSize: 14)),
            value: ref.watch(debugDateProvider)?.month == 11,
            activeColor: BopTheme.green,
            onChanged: (val) {
              ref.read(debugDateProvider.notifier).state = val ? DateTime(2026, 11, 15) : null;
            },
          ),
          SwitchListTile(
            title: const Text('Simulate December (Active)', style: TextStyle(fontSize: 14)),
            value: ref.watch(debugDateProvider)?.month == 12,
            activeColor: BopTheme.green,
            onChanged: (val) {
              ref.read(debugDateProvider.notifier).state = val ? DateTime(2026, 12, 10) : null;
            },
          ),

          _SettingsTile(
            label: 'About',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Bop',
                applicationVersion: '2.3.5',
                applicationIcon: const Icon(Icons.music_note, color: BopTheme.green),
                children: [
                  const Text('Bop v2.3.5 - Aquamid.'),
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
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.label, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: BopTheme.textMuted, fontSize: 12)) : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: BopTheme.textSecondary),
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
              ?.copyWith(color: BopTheme.textMuted)),
    );
  }
}
