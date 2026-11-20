import 'dart:async';
import 'package:flutter/foundation.dart';
import 'day_evening_auto.dart';

class DayNightController {
  DayNightController({this.sunriseHour = 6, this.sunsetHour = 18})
      : isDayNotifier = ValueNotifier<bool>(
          isDaytime(DateTime.now(), sunriseHour: sunriseHour, sunsetHour: sunsetHour),
        ) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  final int sunriseHour;
  final int sunsetHour;
  final ValueNotifier<bool> isDayNotifier;
  Timer? _timer;

  void refresh() {
    final nextIsDay = isDaytime(
      DateTime.now(),
      sunriseHour: sunriseHour,
      sunsetHour: sunsetHour,
    );
    if (isDayNotifier.value != nextIsDay) {
      isDayNotifier.value = nextIsDay;
    }
  }

  void dispose() {
    _timer?.cancel();
    isDayNotifier.dispose();
  }
}