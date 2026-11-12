import 'package:flutter/material.dart';

class AnimatedSwitcherTranslation extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const AnimatedSwitcherTranslation({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  // Using a dynamic list definition to completely eliminate angle bracket compilation bugs
  static const List _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'fr', 'label': 'Français'},
  ];

  @override
  Widget build(BuildContext context) {
    final activeLang = _languages.firstWhere(
      (lang) => lang['code'] == currentLocale.languageCode,
      orElse: () => _languages.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeLang['code'],
          dropdownColor: Colors.black87,
          icon: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.language, size: 16, color: Colors.lightBlueAccent),
          ),
          selectedItemBuilder: (BuildContext context) {
            return _languages.map((lang) {
              return Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    lang['label']!,
                    key: ValueKey<String>(lang['code']!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList();
          },
          items: _languages.map((lang) {
            final isSelected = activeLang['code'] == lang['code'];
            return DropdownMenuItem<String>(
              value: lang['code'],
              child: Text(
                lang['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.lightBlueAccent : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newCode) {
            if (newCode != null) {
              onLocaleChanged(Locale(newCode));
            }
          },
        ),
      ),
    );
  }
}
