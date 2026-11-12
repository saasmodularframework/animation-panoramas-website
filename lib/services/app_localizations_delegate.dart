import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'prev': 'Prev',
      'next': 'Next',
      'scene3d': '3D SCENE',
      'scene2d': '2D SCENE',
    },
    'es': {
      'prev': 'Anterior',
      'next': 'Siguiente',
      'scene3d': 'ESCENA 3D',
      'scene2d': 'ESCENA 2D',
    },
    'de': {
      'prev': 'Zurück',
      'next': 'Weiter',
      'scene3d': '3D-SZENE',
      'scene2d': '2D-SZENE',
    },
    'fr': {
      'prev': 'Préc',
      'next': 'Suiv',
      'scene3d': 'SCÈNE 3D',
      'scene2d': 'SCÈNE 2D',
    },
    'ar': {
      'prev': 'السابق',
      'next': 'التالي',
      'scene3d': 'مشهد ثلاثي الأبعاد',
      'scene2d': 'مشهد ثنائي الأبعاد',
    },
    'hi': {
      'prev': 'पिछला',
      'next': 'अगला',
      'scene3d': '3डी दृश्य',
      'scene2d': '2डी दृश्य',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}