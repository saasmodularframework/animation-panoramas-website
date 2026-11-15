import 'package:flutter/material.dart';

class OpenMeteoLiveWidget extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final bool isFetching;
  final VoidCallback onRefresh;

  const OpenMeteoLiveWidget({
    super.key,
    required this.weatherData,
    required this.isFetching,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final temp = weatherData['temperature_2m'] ?? '--';
    final apparentTemp = weatherData['apparent_temperature'] ?? '--';
    final humidity = weatherData['relative_humidity_2m'] ?? '--';
    final precipitation = weatherData['precipitation'] ?? '--';
    final cloudCover = weatherData['cloud_cover'] ?? '--';
    final pressure = weatherData['surface_pressure'] ?? '--';
    final windSpeed = weatherData['wind_speed_10m'] ?? '--';
    final windDirection = weatherData['wind_direction_10m'] ?? '--';
    final windGusts = weatherData['wind_gusts_10m'] ?? '--';
    final weatherCode = weatherData['weather_code'] ?? '--';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final crossAxisCount = isDesktop ? 5 : 2;
        final childAspectRatio = isDesktop ? 1.8 : 3.0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlueAccent.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_outlined, color: Colors.lightBlueAccent, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        "OPEN-METEO LIVE (10 METRICS)",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.refresh, size: 15, color: isFetching ? Colors.amberAccent : Colors.white70),
                    onPressed: onRefresh,
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 10),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildMetricTile("Temp", "$temp°C", Icons.thermostat, isDesktop),
                  _buildMetricTile("Apparent", "$apparentTemp°C", Icons.device_thermostat, isDesktop),
                  _buildMetricTile("Humidity", "$humidity%", Icons.water_drop, isDesktop),
                  _buildMetricTile("Precip", "$precipitation mm", Icons.umbrella, isDesktop),
                  _buildMetricTile("Clouds", "$cloudCover%", Icons.cloud, isDesktop),
                  _buildMetricTile("Pressure", "$pressure hPa", Icons.speed, isDesktop),
                  _buildMetricTile("Wind Spd", "$windSpeed km/h", Icons.air, isDesktop),
                  _buildMetricTile("Wind Dir", "$windDirection°", Icons.navigation, isDesktop),
                  _buildMetricTile("Gusts", "$windGusts km/h", Icons.storm, isDesktop),
                  _buildMetricTile("Code", "$weatherCode", Icons.code, isDesktop),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, bool isDesktop) {
    if (isDesktop) {
      // Desktop & Tablet screens: 3x bigger (Icon 30px, Label 24px, Value 30px)
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: Colors.lightBlueAccent),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 24, color: Colors.white60),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      // Mobile screens: remains exactly as original baseline layout/sizing
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 32, color: Colors.lightBlueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 14, color: Colors.white60),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }
}