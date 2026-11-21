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

  void _toggle() {
    final t = AppState.toggleTheme; 
    if (t != null) {
      t();
    } else {
      AppState.setManual(dark: AppState.themeMode.value != ThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ValueListenableBuilder<bool>(
        valueListenable: AppState.manualTheme,
        builder: (_, manual, __) => manual
            ? IconButton(
                tooltip: 'auto theme',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.brightness_auto, size: 20),
                onPressed: AppState.resumeAuto,
              )
            : const SizedBox.shrink(),
      ),
      ValueListenableBuilder<ThemeMode>(
        valueListenable: AppState.themeMode,
        builder: (_, mode, __) {
          final night = mode == ThemeMode.dark;
          return Tooltip(
            message: 'theme switcher',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 76,
                  height: 30,
                  decoration: BoxDecoration(
                    color: night ? const Color(0xFF283593) : const Color(0xFFF2B84B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(children: [
                    Align(
                      alignment: night ? Alignment.centerLeft : Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          night ? 'EVENING' : 'DAY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: night ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      alignment: night ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                      
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }
}
