import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../storage/secure_storage.dart';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._secureStorage) : super(ThemeMode.system) {
    _restore();
  }

  final SecureStorage _secureStorage;

  Future<void> _restore() async {
    final saved = await _secureStorage.readThemeMode();
    if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'dark') {
      state = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _secureStorage.saveThemeMode(mode.name);
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(secureStorageProvider));
});
