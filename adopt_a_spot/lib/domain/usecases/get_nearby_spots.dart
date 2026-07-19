import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../entities/spot.dart';
import '../repositories/spot_repository.dart';

class GetNearbySpots implements UseCase<List<Spot>, NearbyParams> {
  final SpotRepository repository;
  const GetNearbySpots(this.repository);

  @override
  Future<Either<Failure, List<Spot>>> call(NearbyParams params) =>
      repository.getNearbySpots(
        lat: params.lat,
        lng: params.lng,
        radius: params.radius,
      );
}

class NearbyParams {
  final double lat;
  final double lng;
  final double radius;
  const NearbyParams({
    required this.lat,
    required this.lng,
    this.radius = 1000,
  });
}
