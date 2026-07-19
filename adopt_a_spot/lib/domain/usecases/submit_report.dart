import 'package:dartz/dartz.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/report_repository.dart';
import '../entities/report.dart'; // ReportResponse

class ReportParams {
  final String spotId;
  final List<String> photoUrls;
  final String issueType;
  final String description;
  final double lat, lng;

  ReportParams({
    required this.spotId,
    required this.photoUrls,
    required this.issueType,
    required this.description,
    required this.lat,
    required this.lng,
  });
}

class SubmitReportUseCase implements UseCase<ReportResponse, ReportParams> {
  final ReportRepository _repo;
  SubmitReportUseCase(this._repo);

  @override
  Future<Either<Failure, ReportResponse>> call(ReportParams p) =>
      _repo.submitReport(
        spotId: p.spotId,
        photoUrls: p.photoUrls,
        issueType: p.issueType,
        description: p.description,
        lat: p.lat,
        lng: p.lng,
      );
}
