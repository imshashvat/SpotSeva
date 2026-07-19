import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String value, label, delta;
  final Color color;

  const KpiCard({
    super.key,
    required this.value,
    required this.label,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2330),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(delta,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
