import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../entities/report.dart';

abstract class ReportRepository {
  Future<Either<Failure, ReportResponse>> submitReport({
    required String spotId,
    required List<String> photoUrls,
    required String issueType,
    required String description,
    required double lat,
    required double lng,
  });

  Stream<List<Report>> watchSpotReports(String spotId);

  Future<Either<Failure, Report>> getReportById(String reportId);

  Future<Either<Failure, void>> updateReportStatus({
    required String reportId,
    required String status,
    String? assignedTo,
  });
}
