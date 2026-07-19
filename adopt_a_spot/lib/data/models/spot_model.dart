import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/spot.dart';

class SpotModel extends Spot {
  const SpotModel({
    required super.id,
    required super.name,
    required super.adopterId,
    required super.geohash,
    required super.geopoint,
    required super.status,
    required super.category,
    required super.checkinsCount,
    required super.lastCheckin,
    required super.ward,
    super.description,
    super.isActive,
  });

  factory SpotModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return SpotModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      adopterId: d['adopterId'] as String? ?? '',
      geohash: d['geohash'] as String? ?? '',
      geopoint: d['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0),
      status: _parseStatus(d['status'] as String? ?? 'clean'),
      category: d['category'] as String? ?? 'Park Furniture',
      checkinsCount: (d['checkinsCount'] as num?)?.toInt() ?? 0,
      lastCheckin: _parseTimestamp(d['lastCheckin']),
      ward: d['ward'] as String? ?? 'Ward 14',
      description: d['description'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  static SpotStatus _parseStatus(String s) {
    switch (s) {
      case 'issue':
        return SpotStatus.issue;
      case 'critical':
        return SpotStatus.critical;
      case 'adopted':
        return SpotStatus.adopted;
      default:
        return SpotStatus.clean;
    }
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'adopterId': adopterId,
        'geohash': geohash,
        'geopoint': geopoint,
        'status': status.name,
        'category': category,
        'checkinsCount': checkinsCount,
        'lastCheckin': Timestamp.fromDate(lastCheckin),
        'ward': ward,
        'description': description,
        'isActive': isActive,
      };
}
