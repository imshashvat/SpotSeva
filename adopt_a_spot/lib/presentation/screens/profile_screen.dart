import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/points/points_bloc.dart';
import '../../../core/constants/app_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }
    final user = authState.user;

    // Start watching wallet
    context.read<PointsBloc>().add(WatchWallet(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: BlocBuilder<PointsBloc, PointsState>(
        builder: (ctx, state) {
          final wallet = state is WalletLoaded ? state.wallet : null;
          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(AppConstants.colorTeal),
                          Color(AppConstants.colorBlue),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          backgroundImage: (user.photoURL?.isNotEmpty ?? false)
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child:
                              (user.photoURL?.isEmpty ?? true)
                                  ? Text(
                                      (user.displayName ?? 'S')[0].toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 32,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.displayName ?? 'SpotSeva User',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          wallet?.adoptedSpotId.isNotEmpty == true
                              ? '📌 Spot adopter'
                              : '🌱 Explorer',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthSignOutRequested());
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: wallet == null
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _ProfileBody(wallet: wallet),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final dynamic wallet;
  const _ProfileBody({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Points overview ──────────────────────────────────
          Row(
            children: [
              _PointsCard(
                value: wallet.balance.toString(),
                label: 'Available Points',
                color: const Color(AppConstants.colorTeal),
                icon: '💎',
              ),
              const SizedBox(width: 12),
              _PointsCard(
                value: wallet.lifetimeEarned.toString(),
                label: 'Total Earned',
                color: const Color(AppConstants.colorBlue),
                icon: '⭐',
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          Row(
            children: [
              _PointsCard(
                value: '${wallet.streak}d',
                label: 'Check-in Streak',
                color: const Color(AppConstants.colorCoral),
                icon: '🔥',
              ),
              const SizedBox(width: 12),
              _PointsCard(
                value: wallet.totalCheckins.toString(),
                label: 'Check-ins Done',
                color: const Color(AppConstants.colorGreen),
                icon: '✅',
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 24),

          // ── Badges ───────────────────────────────────────────
          const Text('Badges',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (wallet.badges.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Complete actions to earn badges!',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (wallet.badges as List<String>)
                  .map((b) => _BadgeChip(badge: b))
                  .toList(),
            ),

          const SizedBox(height: 24),

          // ── Activity ─────────────────────────────────────────
          const Text('Activity',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ActivityRow(
              icon: Icons.report_outlined,
              label: 'Reports submitted',
              value: wallet.totalReports.toString()),
          _ActivityRow(
              icon: Icons.check_circle_outline,
              label: 'Total check-ins',
              value: wallet.totalCheckins.toString()),
          if (wallet.adoptedSpotId.isNotEmpty)
            const _ActivityRow(
                icon: Icons.push_pin_outlined,
                label: 'Active adopted spot',
                value: '1'),

          const SizedBox(height: 24),

          // ── Delete account ───────────────────────────────────
          TextButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline,
                color: Color(AppConstants.colorRed), size: 18),
            label: const Text(
              'Delete Account (DPDP Act 2023)',
              style: TextStyle(
                  color: Color(AppConstants.colorRed), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'All your data will be permanently deleted within 30 days per DPDP Act 2023.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.colorRed)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final String value, label, icon;
  final Color color;
  const _PointsCard(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(AppConstants.colorTeal),
            Color(AppConstants.colorBlue),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badge,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ActivityRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
