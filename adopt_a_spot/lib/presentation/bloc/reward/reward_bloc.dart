import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/reward.dart';
import '../../../domain/repositories/reward_repository.dart';
import '../../../domain/usecases/redeem_coupon.dart';

abstract class RewardEvent extends Equatable {
  @override List<Object?> get props => [];
}
class WatchRewards extends RewardEvent {}
class RedeemCouponEvent extends RewardEvent {
  final String rewardId;
  RedeemCouponEvent(this.rewardId);
  @override List<Object?> get props => [rewardId];
}

abstract class RewardState extends Equatable {
  @override List<Object?> get props => [];
}
class RewardInitial extends RewardState {}
class RewardLoading extends RewardState {}
class RewardsLoaded extends RewardState {
  final List<Reward> rewards;
  RewardsLoaded(this.rewards);
  @override List<Object?> get props => [rewards];
}
class RedeemSuccess extends RewardState {
  final String couponCode;
  final int newBalance;
  final String rewardId;
  RedeemSuccess({required this.couponCode, required this.newBalance, required this.rewardId});
  @override List<Object?> get props => [couponCode, newBalance, rewardId];
}
class RewardError extends RewardState {
  final String message;
  RewardError(this.message);
  @override List<Object?> get props => [message];
}

class RewardBloc extends Bloc<RewardEvent, RewardState> {
  final RedeemCouponUseCase _redeemCoupon;
  final RewardRepository _rewardRepo;

  RewardBloc({
    required RedeemCouponUseCase redeemCoupon,
    required RewardRepository rewardRepo,
  })  : _redeemCoupon = redeemCoupon,
        _rewardRepo = rewardRepo,
        super(RewardInitial()) {
    on<WatchRewards>(_onWatch);
    on<RedeemCouponEvent>(_onRedeem);
  }

  Future<void> _onWatch(WatchRewards event, Emitter<RewardState> emit) {
    return emit.forEach<List<Reward>>(
      _rewardRepo.watchRewards(),
      onData: (rewards) => RewardsLoaded(rewards),
      onError: (_, __) => RewardError('Failed to load rewards'),
    );
  }

  Future<void> _onRedeem(RedeemCouponEvent event, Emitter emit) async {
    emit(RewardLoading());
    final result = await _redeemCoupon(RedeemParams(rewardId: event.rewardId));
    result.fold(
      (f) => emit(RewardError(f.message)),
      (resp) => emit(RedeemSuccess(
        couponCode: resp.couponCode,
        newBalance: resp.newBalance,
        rewardId: event.rewardId,
      )),
    );
  }

}
