import 'package:flutter/material.dart';
import '../../../domain/entities/spot.dart';
import '../../../core/constants/app_constants.dart';

class SpotMarkerWidget extends StatelessWidget {
  final SpotStatus status;
  final bool isMySpot;
  final VoidCallback onTap;

  const SpotMarkerWidget({
    super.key,
    required this.status,
    required this.isMySpot,
    required this.onTap,
  });

  Color _color() {
    if (isMySpot) return const Color(AppConstants.colorPurple);
    switch (status) {
      case SpotStatus.clean:
        return const Color(AppConstants.colorGreen);
      case SpotStatus.issue:
        return const Color(AppConstants.colorAmber);
      case SpotStatus.critical:
        return const Color(AppConstants.colorRed);
      case SpotStatus.adopted:
        return const Color(AppConstants.colorTeal);
    }
  }

  String _emoji() {
    if (isMySpot) return '⭐';
    switch (status) {
      case SpotStatus.clean:
        return '📍';
      case SpotStatus.issue:
        return '⚠️';
      case SpotStatus.critical:
        return '🚨';
      case SpotStatus.adopted:
        return '📌';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _color(),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: isMySpot ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: _color().withValues(alpha: 0.4),
              blurRadius: isMySpot ? 12 : 6,
              spreadRadius: isMySpot ? 3 : 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _emoji(),
            style: TextStyle(fontSize: isMySpot ? 20 : 16),
          ),
        ),
      ),
    );
  }
}
