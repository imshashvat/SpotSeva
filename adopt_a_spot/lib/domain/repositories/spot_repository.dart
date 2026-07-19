import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../entities/spot.dart';

abstract class SpotRepository {
  Future<Either<Failure, List<Spot>>> getNearbySpots({
    required double lat,
    required double lng,
    double radius = 1000,
  });

  Stream<List<Spot>> watchNearbySpots({
    required double lat,
    required double lng,
    double radius = 1000,
  });

  Future<Either<Failure, Spot>> getSpotById(String spotId);

  Future<Either<Failure, AdoptResponse>> adoptSpot(String spotId);

  Future<Either<Failure, CheckInResponse>> checkIn({
    required String spotId,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, void>> releaseSpot(String spotId);
}

class AdoptResponse {
  final int pointsEarned;
  final String spotId;
  const AdoptResponse({required this.pointsEarned, required this.spotId});

  factory AdoptResponse.fromMap(Map<dynamic, dynamic> map) =>
      AdoptResponse(
        pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 50,
        spotId: map['spotId'] as String? ?? '',
      );
}

class CheckInResponse {
  final int pointsEarned;
  final int streak;
  const CheckInResponse({required this.pointsEarned, required this.streak});

  factory CheckInResponse.fromMap(Map<dynamic, dynamic> map) =>
      CheckInResponse(
        pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 10,
        streak: (map['streak'] as num?)?.toInt() ?? 0,
      );
}
