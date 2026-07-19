import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/user_wallet.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/reward_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  const UserRepositoryImpl(this._db, this._auth);

  @override
  Future<Either<Failure, UserWallet>> getUserWallet(String userId) async {
    try {
      final doc = await _db
          .collection(AppConstants.colWallets)
          .doc(userId)
          .get();
      if (!doc.exists) return const Left(ServerFailure('Wallet not found'));
      return Right(_walletFromDoc(doc));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Stream<UserWallet> watchUserWallet(String userId) {
    return _db
        .collection(AppConstants.colWallets)
        .doc(userId)
        .snapshots()
        .where((doc) => doc.exists)
        .map((doc) => _walletFromDoc(doc));
  }

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard(
      String period) async {
    try {
      final field = _periodField(period);
      final snap = await _db
          .collection(AppConstants.colLeaderboard)
          .orderBy(field, descending: true)
          .limit(AppConstants.leaderboardTopN)
          .get();

      final entries = snap.docs
          .asMap()
          .entries
          .map((e) => LeaderboardEntryModel.fromDoc(e.value, e.key + 1))
          .toList();
      return Right(entries);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard(String period) {
    final field = _periodField(period);
    return _db
        .collection(AppConstants.colLeaderboard)
        .orderBy(field, descending: true)
        .limit(AppConstants.leaderboardTopN)
        .snapshots()
        .map((snap) => snap.docs
            .asMap()
            .entries
            .map((e) => LeaderboardEntryModel.fromDoc(e.value, e.key + 1))
            .toList());
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    required String displayName,
  }) async {
    try {
      await _db.collection(AppConstants.colUsers).doc(userId).update({
        'displayName': displayName,
      });
      await _auth.currentUser?.updateDisplayName(displayName);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Update failed'));
    }
  }

  UserWallet _walletFromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return UserWallet(
      userId: doc.id,
      balance: (d['balance'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (d['lifetimeEarned'] as num?)?.toInt() ?? 0,
      streak: (d['streak'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(d['badges'] as List? ?? []),
      displayName: d['displayName'] as String? ?? 'SpotSeva User',
      photoUrl: d['photoUrl'] as String? ?? '',
      role: d['role'] as String? ?? AppConstants.roleCitizen,
      adoptedSpotId: d['adoptedSpotId'] as String? ?? '',
      totalReports: (d['totalReports'] as num?)?.toInt() ?? 0,
      totalCheckins: (d['totalCheckins'] as num?)?.toInt() ?? 0,
      flagged: d['flagged'] as bool? ?? false,
      flagReason: d['flagReason'] as String? ?? '',
    );
  }

  String _periodField(String period) {
    switch (period) {
      case 'week':
        return 'weekPoints';
      case 'month':
        return 'monthPoints';
      default:
        return 'allTimePoints';
    }
  }
}
