import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/reward_repository.dart';
import '../entities/reward.dart'; // RedeemResponse

class RedeemParams {
  final String rewardId;
  RedeemParams({required this.rewardId});
}

class RedeemCouponUseCase implements UseCase<RedeemResponse, RedeemParams> {
  final RewardRepository _repo;
  RedeemCouponUseCase(this._repo);

  @override
  Future<Either<Failure, RedeemResponse>> call(RedeemParams p) =>
      _repo.redeemCoupon(p.rewardId);
}
