import 'package:flutter/material.dart';

class GrafanaMcpDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> telemetry;
  final bool isFetching;
  final VoidCallback onRefresh;

  const GrafanaMcpDashboardWidget({
    super.key,
    required this.telemetry,
    required this.isFetching,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.query_stats, color: Colors.cyanAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "GRAFANA MCP & PARALLEL.AI OLAP",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 16, color: isFetching ? Colors.orangeAccent : Colors.white70),
                onPressed: onRefresh,
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOLAPMetricCard("Sunrise", "${telemetry['sunrise']}", Icons.wb_sunny),
              _buildOLAPMetricCard("Sunset", "${telemetry['sunset']}", Icons.nights_stay),
              _buildOLAPMetricCard("Node State", "${telemetry['status']}", Icons.bolt),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub, size: 14, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Parallel.ai Specimen: ${telemetry['specimen']}",
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOLAPMetricCard(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white60),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
