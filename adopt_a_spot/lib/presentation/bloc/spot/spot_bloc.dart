import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/spot.dart';
import '../../../domain/usecases/get_nearby_spots.dart';
import '../../../domain/usecases/adopt_spot.dart';
import '../../../domain/repositories/spot_repository.dart';

// ── Events ────────────────────────────────────────────────────
abstract class SpotEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadNearbySpots extends SpotEvent {
  final double lat, lng;
  final double radiusMeters;
  LoadNearbySpots(this.lat, this.lng, {this.radiusMeters = 1000});
  @override List<Object?> get props => [lat, lng, radiusMeters];
}

class WatchNearbySpots extends SpotEvent {
  final double lat, lng;
  WatchNearbySpots(this.lat, this.lng);
  @override List<Object?> get props => [lat, lng];
}

class AdoptSpotEvent extends SpotEvent {
  final String spotId;
  AdoptSpotEvent(this.spotId);
  @override List<Object?> get props => [spotId];
}

class CheckInSpotEvent extends SpotEvent {
  final String spotId;
  final double lat, lng;
  CheckInSpotEvent(this.spotId, this.lat, this.lng);
  @override List<Object?> get props => [spotId, lat, lng];
}

class SpotsUpdated extends SpotEvent {
  final List<Spot> spots;
  SpotsUpdated(this.spots);
  @override List<Object?> get props => [spots];
}

// ── States ───────────────────────────────────────────────────
abstract class SpotState extends Equatable {
  @override List<Object?> get props => [];
}

class SpotInitial extends SpotState {}
class SpotLoading extends SpotState {}
class SpotError extends SpotState {
  final String message;
  SpotError(this.message);
  @override List<Object?> get props => [message];
}

class SpotsLoaded extends SpotState {
  final List<Spot> spots;
  SpotsLoaded(this.spots);
  @override List<Object?> get props => [spots];
}

class AdoptionSuccess extends SpotState {
  final int pointsEarned;
  final String spotId;
  AdoptionSuccess(this.pointsEarned, this.spotId);
  @override List<Object?> get props => [pointsEarned, spotId];
}

class CheckInSuccess extends SpotState {
  final int pointsEarned;
  final int currentStreak;
  CheckInSuccess(this.pointsEarned, this.currentStreak);
  @override List<Object?> get props => [pointsEarned, currentStreak];
}

// ── BLoC ─────────────────────────────────────────────────────
class SpotBloc extends Bloc<SpotEvent, SpotState> {
  final GetNearbySpots _getNearbySpots;
  final AdoptSpotUseCase _adoptSpot;
  final CheckInUseCase _checkIn;
  final SpotRepository _spotRepo;

  SpotBloc({
    required GetNearbySpots getNearbySpots,
    required AdoptSpotUseCase adoptSpot,
    required CheckInUseCase checkIn,
    required SpotRepository spotRepo,
  })  : _getNearbySpots = getNearbySpots,
        _adoptSpot = adoptSpot,
        _checkIn = checkIn,
        _spotRepo = spotRepo,
        super(SpotInitial()) {
    on<LoadNearbySpots>(_onLoad);
    on<WatchNearbySpots>(_onWatch);
    on<AdoptSpotEvent>(_onAdopt);
    on<CheckInSpotEvent>(_onCheckIn);
    on<SpotsUpdated>(_onSpotsUpdated);
  }

  Future<void> _onLoad(LoadNearbySpots event, Emitter emit) async {
    emit(SpotLoading());
    final result = await _getNearbySpots(
      NearbyParams(lat: event.lat, lng: event.lng, radius: event.radiusMeters),
    );
    result.fold(
      (f) => emit(SpotError(f.message)),
      (spots) => emit(SpotsLoaded(spots)),
    );
  }

  /// Real-time stream via Firestore — auto-refreshes the map as data changes.
  Future<void> _onWatch(WatchNearbySpots event, Emitter emit) {
    return emit.forEach<List<Spot>>(
      _spotRepo.watchNearbySpots(lat: event.lat, lng: event.lng),
      onData: (spots) => SpotsLoaded(spots),
      onError: (_, __) => SpotError('Failed to load spots'),
    );
  }

  Future<void> _onAdopt(AdoptSpotEvent event, Emitter emit) async {
    emit(SpotLoading());
    final result = await _adoptSpot(AdoptParams(spotId: event.spotId));
    result.fold(
      (f) => emit(SpotError(f.message)),
      (resp) => emit(AdoptionSuccess(resp.pointsEarned, resp.spotId)),
    );
  }

  Future<void> _onCheckIn(CheckInSpotEvent event, Emitter emit) async {
    emit(SpotLoading());
    final result = await _checkIn(
      CheckInParams(spotId: event.spotId, lat: event.lat, lng: event.lng),
    );
    result.fold(
      (f) => emit(SpotError(f.message)),
      (resp) => emit(CheckInSuccess(resp.pointsEarned, resp.streak)),
    );
  }

  void _onSpotsUpdated(SpotsUpdated event, Emitter emit) {
    emit(SpotsLoaded(event.spots));
  }
}
