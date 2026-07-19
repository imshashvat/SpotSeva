// domain/entities/reward.dart
class Reward {
  final String id;
  final String businessId;
  final String businessName;
  final String title;
  final String description;
  final int pointsCost;
  final int totalQty;
  final int redeemedQty;
  final DateTime expiresAt;
  final String category;
  final String imageUrl;
  final bool isFeatured;

  const Reward({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.totalQty,
    required this.redeemedQty,
    required this.expiresAt,
    required this.category,
    required this.imageUrl,
    required this.isFeatured,
  });

  int get remaining => totalQty - redeemedQty;
  bool get isAvailable => remaining > 0 && expiresAt.isAfter(DateTime.now());
}

class RedeemResponse {
  final String couponCode;
  final int newBalance;

  const RedeemResponse({required this.couponCode, required this.newBalance});

  factory RedeemResponse.fromMap(Map data) => RedeemResponse(
    couponCode: data['couponCode'] as String? ?? '',
    newBalance: data['newBalance'] as int? ?? 0,
  );
}

class RedemptionRecord {
  final String id;
  final String rewardId;
  final String couponCode;
  final DateTime redeemedAt;
  final bool used;

  const RedemptionRecord({
    required this.id,
    required this.rewardId,
    required this.couponCode,
    required this.redeemedAt,
    required this.used,
  });
}
