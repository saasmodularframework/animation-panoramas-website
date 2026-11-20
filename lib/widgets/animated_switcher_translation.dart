import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
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

class DayNightSwitch extends StatefulWidget {
  const DayNightSwitch({super.key});

  @override
  State<DayNightSwitch> createState() => _DayNightSwitchState();
}

class _DayNightSwitchState extends State<DayNightSwitch> {
  late final ValueNotifier<bool> _night = ValueNotifier<bool>(AppState.themeMode.value == ThemeMode.dark);

  @override
  void initState() {
    super.initState();
    _night.addListener(_onSwitch);
    AppState.themeMode.addListener(_onTheme);
  }

  void _onSwitch() {
    final dark = _night.value;
    if ((AppState.themeMode.value == ThemeMode.dark) != dark) AppState.setManual(dark: dark);
  }

  void _onTheme() {
    final dark = AppState.themeMode.value == ThemeMode.dark;
    if (_night.value != dark) _night.value = dark;
  }

  @override
  void dispose() {
    AppState.themeMode.removeListener(_onTheme);
    _night.removeListener(_onSwitch);
    _night.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ValueListenableBuilder<bool>(
        valueListenable: AppState.manualTheme,
        builder: (_, manual, __) => manual
            ? IconButton(
                tooltip: 'Auto: follow day / night',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.brightness_auto, size: 20),
                onPressed: AppState.resumeAuto,
              )
            : const SizedBox.shrink(),
      ),
      Tooltip(
        message: 'Day / Night',
        child: AdvancedSwitch(
          controller: _night,
          width: 76,
          height: 30,
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          activeColor: const Color(0xFF283593),
          inactiveColor: const Color(0xFFF2B84B),
          activeChild: const Text('NIGHT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
          inactiveChild: const Text('DAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87)),
          thumb: ValueListenableBuilder<bool>(
            valueListenable: _night,
            builder: (_, night, __) => Container(
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(night ? Icons.nightlight_round : Icons.wb_sunny, size: 16, color: night ? const Color(0xFF283593) : const Color(0xFFE08A00)),
            ),
          ),
        ),
      ),
    ]);
  }
}
