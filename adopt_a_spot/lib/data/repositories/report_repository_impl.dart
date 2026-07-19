import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../models/report_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  const ReportRepositoryImpl(this._db, this._functions, this._storage);

  @override
  Future<Either<Failure, ReportResponse>> submitReport({
    required String spotId,
    required List<String> photoUrls,
    required String issueType,
    required String description,
    required double lat,
    required double lng,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitReport');
      final result = await callable.call({
        'spotId': spotId,
        'photoUrls': photoUrls,
        'issueType': issueType,
        'description': description,
        'lat': lat,
        'lng': lng,
      });
      return Right(ReportResponse.fromMap(result.data as Map));
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(e.message ?? 'Report submission failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Report>> watchSpotReports(String spotId) {
    return _db
        .collection(AppConstants.colReports)
        .where('spotId', isEqualTo: spotId)
        .where('isValid', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ReportModel.fromDoc(d)).toList());
  }

  @override
  Future<Either<Failure, Report>> getReportById(String reportId) async {
    try {
      final doc = await _db
          .collection(AppConstants.colReports)
          .doc(reportId)
          .get();
      if (!doc.exists) return const Left(ServerFailure('Report not found'));
      return Right(ReportModel.fromDoc(doc));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firestore error'));
    }
  }

  @override
  Future<Either<Failure, void>> updateReportStatus({
    required String reportId,
    required String status,
    String? assignedTo,
  }) async {
    try {
      await _db.collection(AppConstants.colReports).doc(reportId).update({
        'status': status,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (status == AppConstants.statusResolved)
          'resolvedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Update failed'));
    }
  }

  // Upload a photo to Firebase Storage and return its download URL
  Future<Either<Failure, String>> uploadPhoto(File imageFile, String userId) async {
    try {
      final ref = _storage.ref(
        'reports/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      return Right(url);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Upload failed'));
    }
  }
}
