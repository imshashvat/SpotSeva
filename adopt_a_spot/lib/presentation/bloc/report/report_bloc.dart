import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/submit_report.dart';

// ── Events ────────────────────────────────────────────────────
abstract class ReportEvent extends Equatable {
  @override List<Object?> get props => [];
}

class UploadPhoto extends ReportEvent {
  final File imageFile;
  final String userId;
  UploadPhoto(this.imageFile, this.userId);
  @override List<Object?> get props => [imageFile.path, userId];
}

class SubmitReport extends ReportEvent {
  final String spotId;
  final List<String> photoUrls;
  final String issueType;
  final String description;
  final double lat;
  final double lng;
  SubmitReport({
    required this.spotId,
    required this.photoUrls,
    required this.issueType,
    required this.description,
    required this.lat,
    required this.lng,
  });
  @override List<Object?> get props => [spotId, photoUrls, issueType, description];
}

class ResetReport extends ReportEvent {}

// ── States ───────────────────────────────────────────────────
abstract class ReportState extends Equatable {
  @override List<Object?> get props => [];
}

class ReportInitial extends ReportState {}
class ReportSubmitting extends ReportState {}
class ReportError extends ReportState {
  final String message;
  ReportError(this.message);
  @override List<Object?> get props => [message];
}

class ReportUploading extends ReportState {
  final double progress;
  ReportUploading({required this.progress});
  @override List<Object?> get props => [progress];
}

class PhotoUploaded extends ReportState {
  final String url;
  PhotoUploaded({required this.url});
  @override List<Object?> get props => [url];
}

class ReportSuccess extends ReportState {
  final String reportId;
  final int pointsEarned;
  final String aiLabel;
  final String severity;
  ReportSuccess({
    required this.reportId,
    required this.pointsEarned,
    required this.aiLabel,
    required this.severity,
  });
  @override List<Object?> get props => [reportId, pointsEarned, aiLabel, severity];
}

// ── BLoC ─────────────────────────────────────────────────────
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final SubmitReportUseCase _submitReport;
  final FirebaseStorage _storage;

  ReportBloc({
    required SubmitReportUseCase submitReport,
    required FirebaseStorage storage,
  })  : _submitReport = submitReport,
        _storage = storage,
        super(ReportInitial()) {
    on<UploadPhoto>(_onUpload);
    on<SubmitReport>(_onSubmit);
    on<ResetReport>((_, emit) => emit(ReportInitial()));
  }

  Future<void> _onUpload(UploadPhoto event, Emitter emit) async {
    emit(ReportUploading(progress: 0));
    try {
      final ref = _storage.ref(
        'reports/${event.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final task = ref.putFile(event.imageFile);
      await for (final snap in task.snapshotEvents) {
        final progress = snap.totalBytes > 0
            ? snap.bytesTransferred / snap.totalBytes
            : 0.0;
        emit(ReportUploading(progress: progress));
      }
      final url = await ref.getDownloadURL();
      emit(PhotoUploaded(url: url));
    } catch (e) {
      emit(ReportError('Photo upload failed: $e'));
    }
  }

  Future<void> _onSubmit(SubmitReport event, Emitter emit) async {
    emit(ReportSubmitting());
    final result = await _submitReport(ReportParams(
      spotId: event.spotId,
      photoUrls: event.photoUrls,
      issueType: event.issueType,
      description: event.description,
      lat: event.lat,
      lng: event.lng,
    ));
    result.fold(
      (f) => emit(ReportError(f.message)),
      (resp) => emit(ReportSuccess(
        reportId: resp.reportId,
        pointsEarned: resp.pointsEarned,
        aiLabel: resp.aiLabel,
        severity: resp.severity,
      )),
    );
  }
}
