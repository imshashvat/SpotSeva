import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/spot_repository.dart';

class AdoptSpotUseCase implements UseCase<AdoptResponse, AdoptParams> {
  final SpotRepository repository;
  const AdoptSpotUseCase(this.repository);

  @override
  Future<Either<Failure, AdoptResponse>> call(AdoptParams params) =>
      repository.adoptSpot(params.spotId);
}

class AdoptParams {
  final String spotId;
  const AdoptParams({required this.spotId});
}

// ──────────────────────────────────────────────────────────────

class CheckInUseCase implements UseCase<CheckInResponse, CheckInParams> {
  final SpotRepository repository;
  const CheckInUseCase(this.repository);

  @override
  Future<Either<Failure, CheckInResponse>> call(CheckInParams params) =>
      repository.checkIn(
        spotId: params.spotId,
        lat: params.lat,
        lng: params.lng,
      );
}

class CheckInParams {
  final String spotId;
  final double lat;
  final double lng;
  const CheckInParams({
    required this.spotId,
    required this.lat,
    required this.lng,
  });
}
