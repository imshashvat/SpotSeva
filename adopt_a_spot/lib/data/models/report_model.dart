import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/report.dart';

class ReportModel extends Report {
  const ReportModel({
    required super.id,
    required super.spotId,
    required super.reporterId,
    required super.photoUrls,
    required super.issueType,
    required super.description,
    required super.aiLabel,
    required super.severity,
    required super.status,
    required super.lat,
    required super.lng,
    required super.createdAt,
    required super.assignedTo,
    super.resolvedAt,
    required super.pointsEarned,
    required super.isValid,
  });

  factory ReportModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    final gp = d['geopoint'] as GeoPoint?;
    return ReportModel(
      id: doc.id,
      spotId: d['spotId'] as String? ?? '',
      reporterId: d['reporterId'] as String? ?? '',
      photoUrls: List<String>.from(d['photoUrls'] as List? ?? []),
      issueType: d['issueType'] as String? ?? '',
      description: d['description'] as String? ?? '',
      aiLabel: d['aiLabel'] as String? ?? 'Issue detected',
      severity: d['severity'] as String? ?? 'low',
      status: d['status'] as String? ?? 'open',
      lat: gp?.latitude ?? 0.0,
      lng: gp?.longitude ?? 0.0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: d['assignedTo'] as String? ?? '',
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
      pointsEarned: d['pointsEarned'] as int? ?? 0,
      isValid: d['isValid'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'spotId': spotId,
    'reporterId': reporterId,
    'photoUrls': photoUrls,
    'issueType': issueType,
    'description': description,
    'aiLabel': aiLabel,
    'severity': severity,
    'status': status,
    'geopoint': GeoPoint(lat, lng),
    'createdAt': Timestamp.fromDate(createdAt),
    'assignedTo': assignedTo,
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'pointsEarned': pointsEarned,
    'isValid': isValid,
  };
}
