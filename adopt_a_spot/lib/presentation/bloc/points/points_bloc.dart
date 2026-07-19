import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_wallet.dart';
import '../../../domain/repositories/user_repository.dart';

// ── Events / States ──────────────────────────────────────────
abstract class PointsEvent extends Equatable {
  @override List<Object?> get props => [];
}

class WatchWallet extends PointsEvent {
  final String userId;
  WatchWallet(this.userId);
  @override List<Object?> get props => [userId];
}

class WatchLeaderboard extends PointsEvent {
  final String period;
  WatchLeaderboard(this.period);
  @override List<Object?> get props => [period];
}

abstract class PointsState extends Equatable {
  @override List<Object?> get props => [];
}

class PointsInitial extends PointsState {}
class PointsLoading extends PointsState {}
class WalletLoaded extends PointsState {
  final UserWallet wallet;
  WalletLoaded(this.wallet);
  @override List<Object?> get props => [wallet];
}
class LeaderboardLoaded extends PointsState {
  final List<LeaderboardEntry> entries;
  final String period;
  LeaderboardLoaded(this.entries, this.period);
  @override List<Object?> get props => [entries, period];
}
class PointsError extends PointsState {
  final String message;
  PointsError(this.message);
  @override List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────
class PointsBloc extends Bloc<PointsEvent, PointsState> {
  final UserRepository _userRepo;

  PointsBloc({required UserRepository userRepo})
      : _userRepo = userRepo,
        super(PointsInitial()) {
    // concurrent:false ensures only one stream subscription at a time
    on<WatchWallet>(_onWatchWallet);
    on<WatchLeaderboard>(_onWatchLeaderboard);
  }

  // Use emit.forEach so BLoC manages the stream lifetime automatically
  Future<void> _onWatchWallet(WatchWallet event, Emitter<PointsState> emit) {
    return emit.forEach<UserWallet>(
      _userRepo.watchUserWallet(event.userId),
      onData: (wallet) => WalletLoaded(wallet),
      onError: (_, __) => PointsError('Failed to load wallet'),
    );
  }

  Future<void> _onWatchLeaderboard(
      WatchLeaderboard event, Emitter<PointsState> emit) {
    return emit.forEach<List<LeaderboardEntry>>(
      _userRepo.watchLeaderboard(event.period),
      onData: (entries) => LeaderboardLoaded(entries, event.period),
      onError: (_, __) => PointsError('Failed to load leaderboard'),
    );
  }
}
