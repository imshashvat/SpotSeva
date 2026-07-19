import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/points/points_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../domain/repositories/user_repository.dart'; // LeaderboardEntry
import '../../core/constants/app_constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _periods = ['week', 'month', 'all'];
  final _labels = ['This Week', 'This Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      context.read<PointsBloc>().add(
            WatchLeaderboard(_periods[_tab.index]),
          );
    });
    context.read<PointsBloc>().add(WatchLeaderboard('week'));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tab,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
          labelColor: const Color(AppConstants.colorTeal),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(AppConstants.colorTeal),
        ),
      ),
      body: BlocBuilder<PointsBloc, PointsState>(
        builder: (ctx, state) {
          if (state is LeaderboardLoaded) {
            return _LeaderboardList(
              entries: state.entries,
              currentUserId: _getCurrentUserId(ctx),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  String _getCurrentUserId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.uid : '';
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String currentUserId;
  const _LeaderboardList(
      {required this.entries, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i];
        final isMe = e.userId == currentUserId;
        return _LeaderboardTile(
          entry: e,
          isMe: isMe,
        ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  const _LeaderboardTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank;
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 24));
    } else if (rank == 2) {
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 24));
    } else if (rank == 3) {
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 24));
    } else {
      rankWidget = Text(
        '#$rank',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black38),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(AppConstants.colorTeal).withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(
                color: const Color(AppConstants.colorTeal),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Center(child: rankWidget)),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(AppConstants.colorTeal)
                .withValues(alpha: 0.2),
            backgroundImage: entry.photoUrl.isNotEmpty
                ? NetworkImage(entry.photoUrl)
                : null,
            child: entry.photoUrl.isEmpty
                ? Text(
                    entry.displayName[0].toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(AppConstants.colorTeal)),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.displayName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isMe
                                ? const Color(AppConstants.colorTeal)
                                : Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.colorTeal),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('You',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.weekPoints} pts',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(AppConstants.colorTeal)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
