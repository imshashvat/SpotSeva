import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/user_repository.dart';

class RewardModel extends Reward {
  const RewardModel({
    required super.id,
    required super.businessId,
    required super.businessName,
    required super.title,
    required super.description,
    required super.pointsCost,
    required super.totalQty,
    required super.redeemedQty,
    required super.expiresAt,
    required super.category,
    required super.imageUrl,
    required super.isFeatured,
  });

  factory RewardModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return RewardModel(
      id: doc.id,
      businessId: d['businessId'] as String? ?? '',
      businessName: d['businessName'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      pointsCost: d['pointsCost'] as int? ?? 0,
      totalQty: d['totalQty'] as int? ?? 0,
      redeemedQty: d['redeemedQty'] as int? ?? 0,
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      category: d['category'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      isFeatured: d['isFeatured'] as bool? ?? false,
    );
  }
}

class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.userId,
    required super.displayName,
    required super.photoUrl,
    required super.rank,
    required super.weekPoints,
    required super.monthPoints,
    required super.allTimePoints,
  });

  factory LeaderboardEntryModel.fromDoc(DocumentSnapshot doc, int rank) {
    final d = doc.data()! as Map<String, dynamic>;
    return LeaderboardEntryModel(
      userId: doc.id,
      displayName: d['displayName'] as String? ?? 'SpotSeva User',
      photoUrl: d['photoUrl'] as String? ?? '',
      rank: rank,
      weekPoints: d['weekPoints'] as int? ?? 0,
      monthPoints: d['monthPoints'] as int? ?? 0,
      allTimePoints: d['allTimePoints'] as int? ?? 0,
    );
  }
}
