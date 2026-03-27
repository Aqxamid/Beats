// ─────────────────────────────────────────────────────────────
// screens/auth/auth_screen.dart
// Start screen: Google sign-in OR Continue as Guest.
// Matches Bop_full_ui_v2 Auth tab exactly.
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import 'username_screen.dart';
import 'guest_notice_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BopTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              // ── Album scatter decoration ──────────────
              _AlbumScatter(),
              const SizedBox(height: 16),

              // ── Logo + headline ───────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: BopTheme.green,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.music_note, color: Colors.black, size: 24),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your music.\nYour way.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  height: 1.2,
                ),
              ),

              const Spacer(),

              // ── CTA buttons ───────────────────────────
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuestNoticeScreen()),
                ),
                child: const Text('Continue as Guest'),
              ),

              const SizedBox(height: 12),
              _dividerLabel(context, '— or sign in to sync —'),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: _GoogleDot(),
                label: const Text('Continue with Google'),
                onPressed: () => _handleGoogleSignIn(context),
              ),

              const SizedBox(height: 16),
              Text(
                'Sign in to sync your stats,\nplaylists & Wrapped history across devices',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();

      if (account != null) {
        // Save username and onboarding flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', account.displayName ?? 'User');
        await prefs.setBool('has_onboarded', true);

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/scan');
        }
      }
    } catch (e) {
      // Google Sign-In failed — fall back to username entry
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UsernameScreen()),
        );
      }
    }
  }

  Widget _dividerLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: BopTheme.textMuted,
      ),
    );
  }
}

// ── Album scatter (decorative colored circles) ────────────────
class _AlbumScatter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF2D6A4F), Color(0xFF5C4A1E), Color(0xFF1A3A5C),
      Color(0xFF4A1942), Color(0xFF3D1A0A), Color(0xFF1A3D21),
    ];
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          _dot(36, 10, 4, colors[0]),
          _dot(30, 50, 2, colors[1]),
          _dot(34, 84, 6, colors[2]),
          _dot(26, 4, 34, colors[3]),
          _dot(38, 56, 26, colors[4]),
          _dot(28, 104, 38, colors[5]),
        ],
      ),
    );
  }

  Widget _dot(double size, double left, double top, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Google color dot ──────────────────────────────────────────
class _GoogleDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: Color(0xFF4285F4),
        shape: BoxShape.circle,
      ),
    );
  }
}
