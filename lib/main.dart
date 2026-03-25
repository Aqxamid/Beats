// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/db_service.dart';
import 'services/llm_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/library/scanning_screen.dart';
import 'providers/player_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize audio service for media notifications
  await initAudioService();

  // Open Isar database
  await DbService.instance.open();

  // Initialize LLM if model path exists
  await LlmService.instance.loadModel();

  // Check if user has already onboarded
  final prefs = await SharedPreferences.getInstance();
  final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

  runApp(ProviderScope(child: BeatSpillApp(hasOnboarded: hasOnboarded)));
}

class BeatSpillApp extends StatelessWidget {
  final bool hasOnboarded;
  const BeatSpillApp({super.key, required this.hasOnboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatSpill',
      debugShowCheckedModeBanner: false,
      theme: BeatSpillTheme.dark,
      // ── Route table ───────────────────────────
      initialRoute: hasOnboarded ? '/home' : '/auth',
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/scan': (_) => const ScanningScreen(),
        '/home': (_) => const MainShell(),
      },
      // ── Deep link: /wrapped/:id ───────────────
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/wrapped') == true) {
          return MaterialPageRoute(builder: (_) => const MainShell());
        }
        return null;
      },
    );
  }
}
