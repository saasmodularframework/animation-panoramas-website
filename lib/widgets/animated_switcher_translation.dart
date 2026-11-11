import 'package:flutter/material.dart';

class AnimatedSwitcherTranslation extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const AnimatedSwitcherTranslation({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  static const Map<String, String> _languages = {
    'en': 'EN',
    'es': 'ES',
    'de': 'DE',
    'fr': 'FR',
    'ar': 'AR',
    'hi': 'HI',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLocale.languageCode,
          dropdownColor: Colors.black87,
          icon: const Icon(Icons.language, size: 16, color: Colors.lightBlueAccent),
          selectedItemBuilder: (BuildContext context) {
            return _languages.keys.map((String code) {
              return Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
                  },
                  child: Text(
                    _languages[code]!,
                    key: ValueKey<String>(code),
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
          items: _languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  color: currentLocale.languageCode == entry.key ? Colors.lightBlueAccent : Colors.white70,
                  fontSize: 12,
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