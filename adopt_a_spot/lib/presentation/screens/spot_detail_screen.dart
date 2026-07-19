import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../bloc/spot/spot_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../../domain/entities/spot.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/points_toast.dart';

class SpotDetailScreen extends StatelessWidget {
  final String spotId;
  const SpotDetailScreen({super.key, required this.spotId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpotBloc, SpotState>(
      listener: (ctx, state) {
        if (state is CheckInSuccess) {
          PointsToast.show(ctx,
              points: state.pointsEarned,
              message: '🔥 Streak: ${state.currentStreak} days!');
          Navigator.pop(ctx);
        }
        if (state is AdoptionSuccess) {
          PointsToast.show(ctx,
              points: state.pointsEarned, message: '📌 Spot adopted!');
          Navigator.pop(ctx);
        }
        if (state is SpotError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(AppConstants.colorRed),
            ),
          );
        }
      },
      builder: (ctx, state) {
        // Find the spot from loaded list
        Spot? spot;
        if (state is SpotsLoaded) {
          try {
            spot = state.spots.firstWhere((s) => s.id == spotId);
          } catch (_) {}
        }

        if (spot == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Spot Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return _SpotDetailBody(spot: spot);
      },
    );
  }
}

class _SpotDetailBody extends StatelessWidget {
  final Spot spot;
  const _SpotDetailBody({required this.spot});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';
    final isMySpot = spot.adopterId == currentUserId;
    final isAdopted = spot.isAdopted;
    final statusColor = _statusColor(spot.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(spot.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusLabel(spot.status),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats row ─────────────────────────────────────
            Row(
              children: [
                _StatBox(
                  value: spot.checkinsCount.toString(),
                  label: 'Check-ins',
                  color: const Color(AppConstants.colorTeal),
                ),
                const SizedBox(width: 12),
                _StatBox(
                  value: _statusLabel(spot.status),
                  label: 'Status',
                  color: statusColor,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  value: spot.category.split(' ').first,
                  label: 'Category',
                  color: const Color(AppConstants.colorBlue),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Info rows ──────────────────────────────────────
            _InfoRow(
              icon: Icons.access_time,
              label:
                  'Last check-in: ${timeago.format(spot.lastCheckin)}',
            ),
            _InfoRow(
              icon: Icons.category,
              label: 'Category: ${spot.category}',
            ),
            _InfoRow(
              icon: Icons.location_city,
              label: 'Ward: ${spot.ward}',
            ),
            if (isMySpot)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.colorPurple)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star,
                        size: 16,
                        color: Color(AppConstants.colorPurple)),
                    SizedBox(width: 6),
                    Text('This is your adopted spot!',
                        style: TextStyle(
                          color: Color(AppConstants.colorPurple),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            if (spot.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                spot.description,
                style: const TextStyle(
                    color: Colors.black54, fontSize: 14, height: 1.5),
              ),
            ],

            const SizedBox(height: 28),
            // ── Action buttons ────────────────────────────────
            if (!isAdopted) ...[
              _PrimaryButton(
                label: '📌 Adopt this Spot  +50 pts',
                color: const Color(AppConstants.colorTeal),
                onTap: () => context
                    .read<SpotBloc>()
                    .add(AdoptSpotEvent(spot.id)),
              ),
              const SizedBox(height: 12),
            ],
            if (isMySpot || !isAdopted) ...[
              _PrimaryButton(
                label: '✅ Check In  +10 pts',
                color: const Color(AppConstants.colorGreen),
                onTap: () => _checkIn(context),
              ),
              const SizedBox(height: 12),
            ],
            _PrimaryButton(
              label: '📸 Report Issue  +25 pts',
              color: const Color(AppConstants.colorCoral),
              onTap: () => context.go('/home/report/${spot.id}'),
            ),
          ],
        ),
      ),
    );
  }

  void _checkIn(BuildContext context) async {
    try {
      final pos = await _getPosition();
      if (!context.mounted) return;
      context.read<SpotBloc>().add(
            CheckInSpotEvent(spot.id, pos.latitude, pos.longitude),
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location')),
      );
    }
  }

  Future<dynamic> _getPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Color _statusColor(SpotStatus s) {
    switch (s) {
      case SpotStatus.clean:
        return const Color(AppConstants.colorGreen);
      case SpotStatus.issue:
        return const Color(AppConstants.colorAmber);
      case SpotStatus.critical:
        return const Color(AppConstants.colorRed);
      case SpotStatus.adopted:
        return const Color(AppConstants.colorPurple);
    }
  }

  String _statusLabel(SpotStatus s) {
    switch (s) {
      case SpotStatus.clean:
        return 'Clean';
      case SpotStatus.issue:
        return 'Issue';
      case SpotStatus.critical:
        return 'Critical';
      case SpotStatus.adopted:
        return 'Adopted';
    }
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
