import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/reward_repository.dart';
import '../models/reward_model.dart';

class RewardRepositoryImpl implements RewardRepository {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  const RewardRepositoryImpl(this._db, this._functions);

  @override
  Future<Either<Failure, List<Reward>>> getRewards() async {
    try {
      final snap = await _db
          .collection(AppConstants.colRewards)
          .orderBy('isFeatured', descending: true)
          .orderBy('pointsCost')
          .get();
      final rewards = snap.docs.map((d) => RewardModel.fromDoc(d)).toList();
      return Right(rewards);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Stream<List<Reward>> watchRewards() {
    return _db
        .collection(AppConstants.colRewards)
        .orderBy('isFeatured', descending: true)
        .orderBy('pointsCost')
        .snapshots()
        .map((s) => s.docs.map((d) => RewardModel.fromDoc(d)).toList());
  }

  @override
  Future<Either<Failure, RedeemResponse>> redeemCoupon(String rewardId) async {
    try {
      final callable = _functions.httpsCallable('redeemCoupon');
      final result = await callable.call({'rewardId': rewardId});
      return Right(RedeemResponse.fromMap(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      final msg = e.message ?? '';
      if (msg.contains('Insufficient')) return const Left(InsufficientPointsFailure());
      if (msg.contains('sold out')) return const Left(CouponSoldOutFailure());
      return Left(ServerFailure(msg));
    }
  }

  @override
  Future<Either<Failure, List<RedemptionRecord>>> getUserRedemptions(
      String userId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colRedemptions)
          .where('userId', isEqualTo: userId)
          .orderBy('redeemedAt', descending: true)
          .get();
      final records = snap.docs.map((d) {
        final data = d.data();
        return RedemptionRecord(
          id: d.id,
          rewardId: data['rewardId'] as String? ?? '',
          couponCode: data['couponCode'] as String? ?? '',
          redeemedAt: (data['redeemedAt'] as dynamic)?.toDate() ?? DateTime.now(),
          used: data['used'] as bool? ?? false,
        );
      }).toList();
      return Right(records);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }
}
