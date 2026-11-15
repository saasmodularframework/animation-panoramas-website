import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/app_strings.dart';

class AnimatedSwitcherTranslation extends StatelessWidget {
  const AnimatedSwitcherTranslation({super.key});

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context);

    String getLabel(Locale l) {
      try {
        final match = AppStrings.languages.firstWhere(
          (element) => element['code'] == l.languageCode,
        );
        return match['label'] ?? l.languageCode.toUpperCase();
      } catch (_) {
        return l.languageCode.toUpperCase();
      }
    }

    final locales = AppStrings.languages.map((e) => Locale(e['code']!)).toList();

    return PopupMenuButton<Locale>(
      tooltip: 'Language',
      initialValue: current,
      onSelected: (l) => AppState.locale.value = l,
      itemBuilder: (_) => [
        for (final l in locales)
          PopupMenuItem<Locale>(
            value: l,
            child: Row(children: [
              Icon(l == current ? Icons.check : Icons.language, size: 18),
              const SizedBox(width: 8),
              Text(getLabel(l)),
            ]),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.translate, size: 20),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(current.languageCode.toUpperCase(), key: ValueKey(current.languageCode)),
          ),
        ]),
      ),
    );
  }
}

class DayNightSwitch extends StatelessWidget {
  const DayNightSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.themeMode,
      builder: (_, mode, __) {
        final dark = mode == ThemeMode.dark;
        return Tooltip(
          message: 'Toggle Theme',
          child: Switch(
            value: dark,
            thumbIcon: WidgetStateProperty.resolveWith(
                (s) => Icon(s.contains(WidgetState.selected) ? Icons.nightlight_round : Icons.wb_sunny)),
            onChanged: (v) => AppState.themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
          ),
        );
      },
    );
  }
}