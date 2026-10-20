import 'package:flutter/material.dart';

class TelemetryObservabilityWidget extends StatelessWidget {
  final List<Map<String, dynamic>> clickHouseLogs;
  final Map<String, dynamic> ecosystemData;

  const TelemetryObservabilityWidget({
    super.key,
    required this.clickHouseLogs,
    required this.ecosystemData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unified Observability & Telemetry',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Chip(
                    label: Text(ecosystemData['status'] ?? 'ONLINE'),
                    backgroundColor: Colors.green.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                    side: BorderSide(color: Colors.green.withOpacity(0.4)),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Colors.white12),
              
              _buildInfoRow(
                context,
                Icons.cloud_done,
                'Grafana Cloud Endpoint',
                'https://micronacho2399.grafana.net (Active)',
                Colors.blueAccent,
              ),
              const SizedBox(height: 12),

              _buildInfoRow(
                context,
                Icons.bolt,
                'Parallel API Search',
                ecosystemData['parallel_api_status'] ?? 'ACTIVE',
                Colors.orangeAccent,
              ),
              const SizedBox(height: 16),

              Text(
                'ClickHouse OLAP Query Execution States',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: clickHouseLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No telemetry logs recorded yet.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: clickHouseLogs.length,
                        itemBuilder: (context, index) {
                          final log = clickHouseLogs[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                            title: Text(
                              'Hour: ${log['hr']} | Metric Avg: ${log['avg_metric']}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Tool: ${log['tool'] ?? 'get_grafana_metrics'}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color iconColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: colorScheme.onSurface)),
          ],
        ),
      ],
    );
  }
}