import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/day_evening_auto.dart';

class AppState {
  static final locale = ValueNotifier<Locale>(const Locale('en'));
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static VoidCallback? toggleTheme;

  static final manualTheme = ValueNotifier<bool>(false);

  static Timer? _timer;

  static void startAutoTheme() {
    _applyAuto();
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => _applyAuto());
  }

  static void _applyAuto() {
    if (manualTheme.value) return;
    themeMode.value = isDaytime(DateTime.now()) ? ThemeMode.light : ThemeMode.dark;
  }

  static void setManual({required bool dark}) {
    manualTheme.value = true;
    themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  static void resumeAuto() {
    manualTheme.value = false;
    _applyAuto();
  }
}
