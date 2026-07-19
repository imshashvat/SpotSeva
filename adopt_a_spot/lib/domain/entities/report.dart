// domain/entities/report.dart
class Report {
  final String id;
  final String spotId;
  final String reporterId;
  final List<String> photoUrls;
  final String issueType;
  final String description;
  final String aiLabel;
  final String severity; // low | medium | high
  final String status;   // open | inProgress | resolved | rejected
  final double lat;
  final double lng;
  final DateTime createdAt;
  final String assignedTo;
  final DateTime? resolvedAt;
  final int pointsEarned;
  final bool isValid;

  const Report({
    required this.id,
    required this.spotId,
    required this.reporterId,
    required this.photoUrls,
    required this.issueType,
    required this.description,
    required this.aiLabel,
    required this.severity,
    required this.status,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.assignedTo,
    this.resolvedAt,
    required this.pointsEarned,
    required this.isValid,
  });
}

class ReportResponse {
  final String reportId;
  final int pointsEarned;
  final String aiLabel;
  final String severity;

  const ReportResponse({
    required this.reportId,
    required this.pointsEarned,
    required this.aiLabel,
    required this.severity,
  });

  factory ReportResponse.fromMap(Map data) => ReportResponse(
    reportId: data['reportId'] as String? ?? '',
    pointsEarned: data['pointsEarned'] as int? ?? 0,
    aiLabel: data['aiLabel'] as String? ?? 'Issue detected',
    severity: data['severity'] as String? ?? 'medium',
  );
}
