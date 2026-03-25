// screens/auth/guest_notice_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class GuestNoticeScreen extends StatelessWidget {
  const GuestNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 32),
              const SizedBox(height: 16),
              Text(
                "You're in guest mode",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your music plays offline.\nSign in anytime to sync your stats & Wrapped across devices.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4285F4),
                    shape: BoxShape.circle,
                  ),
                ),
                label: const Text('Sign in with Google'),
                onPressed: () {
                  // TODO: trigger Google OAuth
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // Mark as onboarded so welcome screen won't show again
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('has_onboarded', true);
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/scan');
                  }
                },
                child: Text(
                  'Stay as guest →',
                  style: TextStyle(color: BeatSpillTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
