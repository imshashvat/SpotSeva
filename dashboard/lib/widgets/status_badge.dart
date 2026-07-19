import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config['color']!.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        config['label']! as String,
        style: TextStyle(
          color: config['color']! as Color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Map<String, dynamic> _config() {
    switch (status) {
      case 'open':
        return {'label': 'OPEN', 'color': const Color(0xFFA32D2D)};
      case 'inProgress':
        return {'label': 'IN PROGRESS', 'color': const Color(0xFFAA6C00)};
      case 'resolved':
        return {'label': 'RESOLVED', 'color': const Color(0xFF2E7D52)};
      case 'rejected':
        return {'label': 'REJECTED', 'color': const Color(0xFF555555)};
      default:
        return {'label': status.toUpperCase(), 'color': Colors.grey};
    }
  }
}
