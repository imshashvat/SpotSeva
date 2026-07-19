import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../entities/reward.dart';

abstract class RewardRepository {
  Future<Either<Failure, List<Reward>>> getRewards();
  Stream<List<Reward>> watchRewards();
  Future<Either<Failure, RedeemResponse>> redeemCoupon(String rewardId);
  Future<Either<Failure, List<RedemptionRecord>>> getUserRedemptions(String userId);
}
