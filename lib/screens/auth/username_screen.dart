// screens/auth/username_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/scan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: BopTheme.background,
        leading: const BackButton(color: BopTheme.textSecondary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              "What's your name?",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'This shows on your Wrapped & profile',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: BopTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'your_username',
                hintStyle: const TextStyle(color: BopTheme.textMuted),
                filled: true,
                fillColor: BopTheme.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _onSubmit(),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep it fun — this shows up in your Wrapped recap',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BopTheme.textMuted,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _hasText ? _onSubmit : null,
              child: const Text("Let's go"),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
