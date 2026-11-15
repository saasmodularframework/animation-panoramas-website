import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  static final Map<String, Map<String, dynamic>> _cache = {};

  Future<Map<String, dynamic>?> fetchWeather(double lat, double lng) async {
    final cacheKey = "weather_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}";
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,cloud_cover,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code',
        },
      );
      if (response.statusCode == 200) {
        final current = response.data['current'];
        if (current != null) {
          _cache[cacheKey] = current;
          return current;
        }
      }
    } catch (e) {
      print("Weather fetch error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchSolarTimes(double lat, double lng) async {
    final cacheKey = "solar_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}";
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final response = await _dio.get(
        'https://api.sunrise-sunset.org/json',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'formatted': 0,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          _cache[cacheKey] = data;
          return data;
        }
      }
    } catch (e) {
      print("Solar times fetch error: $e");
    }
    return null;
  }

  Future<String?> fetchWildlifeSample(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://api.gbif.org/v1/occurrence/search',
        queryParameters: {
          'decimalLatitude': lat,
          'decimalLongitude': lng,
          'limit': 1,
        },
      );
      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['scientificName'] ?? 
                 results[0]['vernacularName'] ?? 
                 'Uncataloged Specimen';
        }
      }
    } catch (e) {
      print("GBIF wildlife fetch error: $e");
    }
    return 'No regional sample found';
  }
}