// screens/library/scanning_screen.dart
// Full-screen loading UI shown while scanning device for music files.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/scanner_service.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  int _current = 0;
  int _total = 0;
  String _statusText = 'Requesting permission…';
  bool _done = false;
  int _added = 0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final scanner = ScannerService.instance;

    // Request permission
    final granted = await scanner.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() => _statusText = 'Storage permission denied');
        // Still navigate to home after delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    setState(() => _statusText = 'Scanning your music…');

    final added = await scanner.scanAndSave(
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _current = current;
            _total = total;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _done = true;
        _added = added;
        _statusText = added > 0
            ? 'Found $added new songs!'
            : 'Your library is up to date';
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeatSpillTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: BeatSpillTheme.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note, color: Colors.black, size: 32),
                  ),
                ),
                const SizedBox(height: 32),

                // Status text
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: BeatSpillTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Progress count
                if (_total > 0)
                  Text(
                    '$_current / $_total files',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeatSpillTheme.textMuted,
                    ),
                  ),
                const SizedBox(height: 24),

                // Progress indicator
                if (!_done)
                  SizedBox(
                    width: 200,
                    child: _total > 0
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _current / _total,
                              backgroundColor: BeatSpillTheme.surfaceAlt,
                              valueColor: const AlwaysStoppedAnimation(
                                  BeatSpillTheme.green),
                              minHeight: 4,
                            ),
                          )
                        : const LinearProgressIndicator(
                            backgroundColor: BeatSpillTheme.surfaceAlt,
                            valueColor: AlwaysStoppedAnimation(
                                BeatSpillTheme.green),
                            minHeight: 4,
                          ),
                  ),

                // Done checkmark
                if (_done) ...[
                  const Icon(Icons.check_circle,
                      color: BeatSpillTheme.green, size: 36),
                  if (_added > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Added to your library',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeatSpillTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
