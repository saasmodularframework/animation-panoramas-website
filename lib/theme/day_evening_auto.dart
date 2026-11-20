bool isDaytime(DateTime now, {int sunriseHour = 6, int sunsetHour = 18}) {
  final h = now.hour;
  return h >= sunriseHour && h < sunsetHour;
}
