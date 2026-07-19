import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:adopt_a_spot/domain/usecases/adopt_spot.dart';
import 'package:adopt_a_spot/domain/repositories/spot_repository.dart';
import 'package:adopt_a_spot/core/error/failure.dart';

class MockSpotRepository extends Mock implements SpotRepository {}

void main() {
  late MockSpotRepository mockRepo;
  late AdoptSpotUseCase useCase;
  late CheckInUseCase checkInUseCase;

  setUp(() {
    mockRepo = MockSpotRepository();
    useCase = AdoptSpotUseCase(mockRepo);
    checkInUseCase = CheckInUseCase(mockRepo);
  });

  group('AdoptSpotUseCase', () {
    const tSpotId = 'spot_123';
    const tResponse = AdoptResponse(spotId: tSpotId, pointsEarned: 50);

    test('should return AdoptResponse on success', () async {
      when(() => mockRepo.adoptSpot(tSpotId))
          .thenAnswer((_) async => const Right(tResponse));

      final result = await useCase(const AdoptParams(spotId: tSpotId));

      expect(result, const Right(tResponse));
      verify(() => mockRepo.adoptSpot(tSpotId)).called(1);
    });

    test('should return AlreadyAdoptedFailure when spot is already taken', () async {
      when(() => mockRepo.adoptSpot(tSpotId))
          .thenAnswer((_) async => const Left(AlreadyAdoptedFailure()));

      final result = await useCase(const AdoptParams(spotId: tSpotId));

      expect(result, const Left(AlreadyAdoptedFailure()));
    });
  });

  group('CheckInUseCase', () {
    const tSpotId = 'spot_456';
    const tLat = 28.4712;
    const tLng = 77.5038;
    const tResponse = CheckInResponse(pointsEarned: 10, streak: 3);

    // Register fallback value so mocktail can handle named params
    setUpAll(() {
      registerFallbackValue(const CheckInParams(
        spotId: tSpotId,
        lat: tLat,
        lng: tLng,
      ));
    });

    test('should return CheckInResponse on success', () async {
      when(() => mockRepo.checkIn(
            spotId: any(named: 'spotId'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          )).thenAnswer((_) async => const Right(tResponse));

      final result = await checkInUseCase(
          const CheckInParams(spotId: tSpotId, lat: tLat, lng: tLng));

      expect(result, const Right(tResponse));
      verify(() => mockRepo.checkIn(
            spotId: tSpotId,
            lat: tLat,
            lng: tLng,
          )).called(1);
    });

    test('should return TooFarFailure when user is more than 100m away',
        () async {
      when(() => mockRepo.checkIn(
            spotId: any(named: 'spotId'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          )).thenAnswer((_) async => const Left(TooFarFailure()));

      final result = await checkInUseCase(
          const CheckInParams(spotId: tSpotId, lat: tLat, lng: tLng));

      expect(result, const Left(TooFarFailure()));
    });

    test('should return DailyLimitFailure when daily limit reached', () async {
      when(() => mockRepo.checkIn(
            spotId: any(named: 'spotId'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          )).thenAnswer((_) async => const Left(DailyLimitFailure()));

      final result = await checkInUseCase(
          const CheckInParams(spotId: tSpotId, lat: tLat, lng: tLng));

      expect(result, const Left(DailyLimitFailure()));
    });
  });
}
