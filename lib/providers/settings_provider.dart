import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final boldDesignProvider = StateNotifierProvider<BoldDesignNotifier, bool>((ref) {
  return BoldDesignNotifier();
});

class BoldDesignNotifier extends StateNotifier<bool> {
  BoldDesignNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('use_bold_design') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_bold_design', state);
  }
}
