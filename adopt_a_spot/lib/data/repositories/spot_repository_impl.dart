import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/spot.dart';
import '../../domain/repositories/spot_repository.dart';
import '../models/spot_model.dart';

class SpotRepositoryImpl implements SpotRepository {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  const SpotRepositoryImpl(this._db, this._functions);

  // ── Geohash helpers ──────────────────────────────────────────
  String _geohash(double lat, double lng, int precision) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    double minLat = -90.0, maxLat = 90.0;
    double minLng = -180.0, maxLng = 180.0;
    var hash = '';
    var bits = 0, hashValue = 0;
    var isEven = true;

    while (hash.length < precision) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          hashValue = (hashValue << 1) | 1;
          minLng = mid;
        } else {
          hashValue = hashValue << 1;
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          hashValue = (hashValue << 1) | 1;
          minLat = mid;
        } else {
          hashValue = hashValue << 1;
          maxLat = mid;
        }
      }
      isEven = !isEven;
      bits++;
      if (bits == 5) {
        hash += base32[hashValue];
        bits = 0;
        hashValue = 0;
      }
    }
    return hash;
  }

  // Taylor-series cosine (accurate enough for ~100 km proximity use)
  double _cosDeg(double deg) {
    final rad = deg * 3.14159265358979 / 180;
    return 1 - (rad * rad) / 2 + (rad * rad * rad * rad) / 24;
  }

  // ── Real-time stream ─────────────────────────────────────────
  @override
  Stream<List<Spot>> watchNearbySpots({
    required double lat,
    required double lng,
    double radius = 1000,
  }) {
    final prefix = _geohash(lat, lng, 4); // 4-char ≈ 39 km × 20 km cell
    return _db
        .collection(AppConstants.colSpots)
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThan: '$prefix~')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SpotModel.fromDoc(d))
            .where((s) =>
                _distanceMeters(lat, lng, s.geopoint.latitude,
                    s.geopoint.longitude) <=
                radius)
            .toList());
  }

  @override
  Future<Either<Failure, List<Spot>>> getNearbySpots({
    required double lat,
    required double lng,
    double radius = 1000,
  }) async {
    try {
      final prefix = _geohash(lat, lng, 4);
      final snap = await _db
          .collection(AppConstants.colSpots)
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~')
          .where('isActive', isEqualTo: true)
          .get();

      final spots = snap.docs
          .map((d) => SpotModel.fromDoc(d))
          .where((s) =>
              _distanceMeters(lat, lng, s.geopoint.latitude,
                  s.geopoint.longitude) <=
              radius)
          .toList();

      return Right(spots);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Spot>> getSpotById(String spotId) async {
    try {
      final doc =
          await _db.collection(AppConstants.colSpots).doc(spotId).get();
      if (!doc.exists) return const Left(ServerFailure('Spot not found'));
      return Right(SpotModel.fromDoc(doc));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, AdoptResponse>> adoptSpot(String spotId) async {
    try {
      final callable = _functions.httpsCallable('adoptSpot');
      final result = await callable.call({'spotId': spotId});
      return Right(AdoptResponse.fromMap(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      final msg = e.message ?? '';
      if (msg.contains('already') || msg.contains('taken')) {
        return const Left(AlreadyAdoptedFailure());
      }
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CheckInResponse>> checkIn({
    required String spotId,
    required double lat,
    required double lng,
  }) async {
    try {
      final callable = _functions.httpsCallable('checkIn');
      final result = await callable.call({
        'spotId': spotId,
        'lat': lat,
        'lng': lng,
      });
      return Right(CheckInResponse.fromMap(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      final msg = e.message ?? '';
      if (msg.contains('too far')) return const Left(TooFarFailure());
      if (msg.contains('limit')) return const Left(DailyLimitFailure());
      return Left(ServerFailure(msg));
    }
  }

  @override
  Future<Either<Failure, void>> releaseSpot(String spotId) async {
    try {
      final callable = _functions.httpsCallable('releaseSpot');
      await callable.call({'spotId': spotId});
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Release failed'));
    }
  }

  // ── Haversine distance (metres) ──────────────────────────────
  double _distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * 3.14159265358979 / 180;
    final dLng = (lng2 - lng1) * 3.14159265358979 / 180;
    final sinHalfLat = _sinHalf(dLat);
    final sinHalfLng = _sinHalf(dLng);
    final a = sinHalfLat * sinHalfLat +
        _cosDeg(lat1) * _cosDeg(lat2) * sinHalfLng * sinHalfLng;
    final c = 2 * _atan(a);
    return r * c;
  }

  double _sinHalf(double x) {
    final h = x / 2;
    return h - (h * h * h) / 6 + (h * h * h * h * h) / 120;
  }

  double _atan(double x) {
    // atan2(sqrt(a), sqrt(1-a)) approximation for small a
    if (x <= 0) return 0;
    if (x >= 1) return 3.14159265358979 / 2;
    final s = x < 0.5 ? x : (1 - x);
    return s - (s * s * s) / 3 + (s * s * s * s * s) / 5;
  }
}
