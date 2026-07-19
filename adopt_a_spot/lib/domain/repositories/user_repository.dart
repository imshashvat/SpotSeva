import 'package:dartz/dartz.dart';
import '../../../core/error/failure.dart';
import '../entities/user_wallet.dart';

abstract class UserRepository {
  Future<Either<Failure, UserWallet>> getUserWallet(String userId);
  Stream<UserWallet> watchUserWallet(String userId);
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard(String period);
  Stream<List<LeaderboardEntry>> watchLeaderboard(String period);
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    required String displayName,
  });
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String photoUrl;
  final int rank;
  final int weekPoints;
  final int monthPoints;
  final int allTimePoints;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.rank,
    required this.weekPoints,
    required this.monthPoints,
    required this.allTimePoints,
  });
}
