// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/db_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/library/scanning_screen.dart';

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

  // Open Isar database
  await DbService.instance.open();

  runApp(const ProviderScope(child: BeatSpillApp()));
}

class BeatSpillApp extends StatelessWidget {
  const BeatSpillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatSpill',
      debugShowCheckedModeBanner: false,
      theme: BeatSpillTheme.dark,
      // ── Route table ───────────────────────────
      initialRoute: '/auth',
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/scan': (_) => const ScanningScreen(),
        '/home': (_) => const MainShell(),
      },
      // ── Deep link: /wrapped/:id ───────────────
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/wrapped') == true) {
          // TODO: parse wrapped report ID from route and push slideshow
          return MaterialPageRoute(builder: (_) => const MainShell());
        }
        return null;
      },
    );
  }
}
