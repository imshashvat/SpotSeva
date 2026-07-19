import 'package:equatable/equatable.dart';

class UserWallet extends Equatable {
  final String userId;
  final int balance;
  final int lifetimeEarned;
  final int streak;
  final DateTime? lastCheckinDate;
  final List<String> badges;
  final String displayName;
  final String photoUrl;
  final String role;
  final String adoptedSpotId;
  final int totalReports;
  final int totalCheckins;
  final bool flagged;
  final String flagReason;

  const UserWallet({
    required this.userId,
    required this.balance,
    required this.lifetimeEarned,
    required this.streak,
    required this.badges,
    required this.displayName,
    this.photoUrl = '',
    this.role = 'citizen',
    this.adoptedSpotId = '',
    this.totalReports = 0,
    this.totalCheckins = 0,
    this.lastCheckinDate,
    this.flagged = false,
    this.flagReason = '',
  });

  @override
  List<Object?> get props => [
        userId, balance, lifetimeEarned, streak, badges,
        displayName, photoUrl, role, adoptedSpotId,
        totalReports, totalCheckins, lastCheckinDate, flagged,
      ];
}
