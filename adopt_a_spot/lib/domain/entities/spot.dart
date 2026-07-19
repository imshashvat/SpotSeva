import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SpotStatus { clean, issue, critical, adopted }

class Spot extends Equatable {
  final String id;
  final String name;
  final String adopterId;
  final String geohash;
  final GeoPoint geopoint;
  final SpotStatus status;
  final String category;
  final int checkinsCount;
  final DateTime lastCheckin;
  final String ward;
  final String description;
  final bool isActive;

  const Spot({
    required this.id,
    required this.name,
    required this.adopterId,
    required this.geohash,
    required this.geopoint,
    required this.status,
    required this.category,
    required this.checkinsCount,
    required this.lastCheckin,
    required this.ward,
    this.description = '',
    this.isActive = true,
  });

  bool get isAdopted => adopterId.isNotEmpty;

  @override
  List<Object?> get props => [
        id, name, adopterId, geohash, geopoint, status,
        category, checkinsCount, lastCheckin, ward, description, isActive,
      ];
}
