import 'package:flutter/material.dart';

const _seed = Color(0xFF1B5C2A);

ThemeData buildDayTheme() {
  const bg = Color(0xFFDCE5D9); // page background
  final scheme = ColorScheme.fromSeed(seedColor: _seed).copyWith(
    surface: bg,
    surfaceContainerLowest: const Color(0xFFE9EFE6),
    surfaceContainerLow: const Color(0xFFE3EBE0),
    surfaceContainer: const Color(0xFFD7E1D4),
    surfaceContainerHigh: const Color(0xFFCFDACB),
    surfaceContainerHighest: const Color(0xFFC6D3C2),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFC9D6C5),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(color: scheme.surfaceContainerLow),
  );
}

ThemeData buildNightTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
    );
