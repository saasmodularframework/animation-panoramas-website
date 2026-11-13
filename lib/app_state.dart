import 'package:flutter/material.dart';

class AppState {
  static final locale = ValueNotifier<Locale>(const Locale('en'));
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);
}
