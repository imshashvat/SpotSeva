import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/spot/spot_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../../domain/entities/spot.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/spot_marker.dart';
import '../widgets/points_toast.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription? _spotStream;
  Position? _currentPosition;
  bool _locationLoaded = false;
  bool _isFindingLocation = true;

  static const _defaultCenter = LatLng(
    AppConstants.defaultLat,
    AppConstants.defaultLng,
  );

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = pos;
        _locationLoaded = true;
        _isFindingLocation = false;
      });
      // Start real-time spot stream
      _startSpotStream(pos.latitude, pos.longitude);

      // Animate camera to user location
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        AppConstants.defaultZoom,
      );
    } catch (e) {
      setState(() => _isFindingLocation = false);
      // Fall back to default center
      _startSpotStream(AppConstants.defaultLat, AppConstants.defaultLng);
    }
  }

  void _startSpotStream(double lat, double lng) {
    context.read<SpotBloc>().add(LoadNearbySpots(lat, lng));
  }

  @override
  void dispose() {
    _spotStream?.cancel();
    super.dispose();
  }


  List<Marker> _buildMarkers(List<Spot> spots) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.uid
        : '';

    return spots.map((spot) {
      final isMySpot = spot.adopterId == currentUserId;
      return Marker(
        point: LatLng(spot.geopoint.latitude, spot.geopoint.longitude),
        width: isMySpot ? 48 : 36,
        height: isMySpot ? 48 : 36,
        child: SpotMarkerWidget(
          status: spot.status,
          isMySpot: isMySpot,
          onTap: () => context.go('/home/spot/${spot.id}'),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SpotBloc, SpotState>(
        listener: (ctx, state) {
          if (state is CheckInSuccess) {
            PointsToast.show(
              ctx,
              points: state.pointsEarned,
              message: '🔥 Streak: ${state.currentStreak} days',
            );
          }
          if (state is AdoptionSuccess) {
            PointsToast.show(
              ctx,
              points: state.pointsEarned,
              message: '📌 Spot adopted!',
            );
          }
          if (state is SpotError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(AppConstants.colorRed),
              ),
            );
          }
        },
        builder: (ctx, state) {
          final spots =
              state is SpotsLoaded ? state.spots : <Spot>[];
          return Stack(
            children: [
              // ── OpenStreetMap ────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _locationLoaded && _currentPosition != null
                      ? LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude)
                      : _defaultCenter,
                  initialZoom: AppConstants.defaultZoom,
                  minZoom: 10,
                  maxZoom: 19,
                ),
                children: [
                  // OSM Tile Layer
                  TileLayer(
                    // CartoDB Voyager — CORS-enabled, free, no API key needed
                    urlTemplate:
                        'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                    userAgentPackageName: 'com.shashvat.adopt_a_spot',
                    maxZoom: 19,
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  // Clustered Spot Markers
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 70,
                      size: const Size(48, 48),
                      markers: _buildMarkers(spots),
                      builder: (context, markers) => Container(
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.colorTeal),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${markers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // User location blue dot
                  if (_locationLoaded && _currentPosition != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          radius: 10,
                          color: Colors.blue.withValues(alpha: 0.8),
                          borderStrokeWidth: 2,
                          borderColor: Colors.white,
                        ),
                        // 100m proximity ring
                        CircleMarker(
                          point: LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          radius: 100,
                          useRadiusInMeter: true,
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderStrokeWidth: 1.5,
                          borderColor: Colors.blue.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  // OSM Attribution
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),

              // ── Top search bar ───────────────────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: _buildSearchBar(spots.length),
              ),

              // ── Legend ───────────────────────────────────────
              Positioned(
                bottom: 100,
                left: 16,
                child: _buildLegend(),
              ),

              // ── Loading overlay ──────────────────────────────
              if (_isFindingLocation || state is SpotLoading)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Finding nearby spots…',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // My location button
          FloatingActionButton.small(
            heroTag: 'locate',
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(_currentPosition!.latitude,
                      _currentPosition!.longitude),
                  AppConstants.defaultZoom,
                );
              } else {
                _initLocation();
              }
            },
            backgroundColor: Colors.white,
            foregroundColor: const Color(AppConstants.colorTeal),
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          // Adopt a Spot button
          FloatingActionButton.extended(
            heroTag: 'adopt',
            onPressed: () => _showAdoptInfo(context),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Adopt a Spot'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(int spotCount) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$spotCount spots nearby',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(AppConstants.colorTeal).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '● Live',
              style: TextStyle(
                color: Color(AppConstants.colorTeal),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(const Color(AppConstants.colorGreen), 'Clean (Available)'),
          const SizedBox(height: 4),
          _legendRow(const Color(AppConstants.colorAmber), 'Issue Reported'),
          const SizedBox(height: 4),
          _legendRow(const Color(AppConstants.colorPurple), 'Your Adopted Spot'),
          const SizedBox(height: 4),
          _legendRow(const Color(AppConstants.colorRed), 'High Priority'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  void _showAdoptInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('How to Adopt a Spot',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Tap any green marker on the map to view spot details and adopt it.\n\n'
              '• One spot per citizen at a time\n'
              '• Earn +50 points on adoption\n'
              '• Check in daily for +10 points\n'
              '• Report issues for +25 points',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
