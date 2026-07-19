import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../bloc/reward/reward_bloc.dart';
import '../bloc/points/points_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../../domain/entities/reward.dart';
import '../../../core/constants/app_constants.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RewardBloc>().add(WatchRewards());
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<PointsBloc>().add(WatchWallet(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Rewards Store'),
        actions: [
          BlocBuilder<PointsBloc, PointsState>(
            builder: (_, state) {
              final balance =
                  state is WalletLoaded ? state.wallet.balance : 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('💎',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('$balance pts',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(AppConstants.colorTeal))),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<RewardBloc, RewardState>(
        listener: (ctx, state) {
          if (state is RedeemSuccess) {
            context.go('/rewards/coupon/${state.rewardId}',
                extra: state.couponCode);
          }
          if (state is RewardError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(AppConstants.colorRed),
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is RewardsLoaded) {
            final featured =
                state.rewards.where((r) => r.isFeatured).toList();
            final regular =
                state.rewards.where((r) => !r.isFeatured).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (featured.isNotEmpty) ...[
                  const Text('⭐ Featured Offers',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      itemBuilder: (_, i) => _FeaturedCard(
                        reward: featured[i],
                        onRedeem: () => _confirmRedeem(ctx, featured[i]),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: i * 80)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Text('All Rewards',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...regular.asMap().entries.map((e) => _RewardCard(
                      reward: e.value,
                      onRedeem: () => _confirmRedeem(ctx, e.value),
                    ).animate().fadeIn(
                        delay: Duration(milliseconds: e.key * 60))),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _confirmRedeem(BuildContext context, Reward reward) {
    final walletState = context.read<PointsBloc>().state;
    final balance =
        walletState is WalletLoaded ? walletState.wallet.balance : 0;

    if (balance < reward.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Need ${reward.pointsCost - balance} more points to redeem!'),
          backgroundColor: const Color(AppConstants.colorAmber),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Redemption'),
        content: Text(
          'Redeem "${reward.title}" for ${reward.pointsCost} points?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<RewardBloc>()
                  .add(RedeemCouponEvent(reward.id));
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onRedeem;
  const _FeaturedCard({required this.reward, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConstants.colorTeal),
            Color(AppConstants.colorBlue),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(AppConstants.colorTeal).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reward.businessName,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(reward.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${reward.pointsCost} pts',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text('${reward.remaining} left',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: reward.isAvailable ? onRedeem : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(AppConstants.colorTeal),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                reward.isAvailable ? 'Redeem' : 'Sold Out',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onRedeem;
  const _RewardCard({required this.reward, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(AppConstants.colorTeal).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(_emoji(reward.category),
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.businessName,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45)),
                Text(reward.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text('${reward.pointsCost} pts',
                        style: const TextStyle(
                            color: Color(AppConstants.colorTeal),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(
                      '${reward.remaining} of ${reward.totalQty} left',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black38),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: reward.isAvailable ? onRedeem : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.colorTeal),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Get',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _emoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
      case 'café':
        return '☕';
      case 'grocery':
        return '🛒';
      case 'entertainment':
        return '🎬';
      case 'recognition':
        return '🏆';
      default:
        return '🎁';
    }
  }
}
