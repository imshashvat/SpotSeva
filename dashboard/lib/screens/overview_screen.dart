import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/kpi_card.dart';
import '../widgets/report_detail_panel.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ─────────────────────────────────────────
          _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Row
                  _KpiRow(),
                  const SizedBox(height: 24),
                  // Map + Priority Queue
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _HeatmapCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _PriorityQueue()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Recent activity
                  _RecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: const Color(0xFF141821),
      child: Row(
        children: [
          const Text('Municipal Command Centre',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF82CFB5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Ward 14 · Greater Noida',
                style: TextStyle(color: Color(0xFF82CFB5), fontSize: 11)),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFF82CFB5), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text('Live',
              style: TextStyle(color: Color(0xFF82CFB5), fontSize: 11)),
        ],
      ),
    );
  }
}

// ── KPI Row with real-time Firestore streams ─────────────────
class _KpiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', whereIn: ['open', 'inProgress', 'resolved'])
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final open = docs.where((d) =>
            (d.data() as Map)['status'] == 'open').length;
        final inProgress = docs.where((d) =>
            (d.data() as Map)['status'] == 'inProgress').length;
        final resolved = docs.where((d) =>
            (d.data() as Map)['status'] == 'resolved').length;

        return Row(
          children: [
            KpiCard(
              value: open.toString(),
              label: 'Open Reports',
              delta: '+3 today',
              color: const Color(0xFF993C1D),
            ),
            const SizedBox(width: 14),
            KpiCard(
              value: inProgress.toString(),
              label: 'In Progress',
              delta: 'Assigned',
              color: const Color(0xFF854F0B),
            ),
            const SizedBox(width: 14),
            KpiCard(
              value: resolved.toString(),
              label: 'Resolved (Month)',
              delta: '▲ Improving',
              color: const Color(0xFF2E7D52),
            ),
            const SizedBox(width: 14),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spots')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (_, snap2) {
                final total = snap2.data?.docs.length ?? 0;
                final adopted = snap2.data?.docs
                        .where((d) =>
                            ((d.data() as Map)['adopterId'] as String?)
                                ?.isNotEmpty ==
                            true)
                        .length ??
                    0;
                return KpiCard(
                  value: '$adopted/$total',
                  label: 'Spots Adopted',
                  delta: 'Active spots',
                  color: const Color(0xFF185FA5),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Real-time Heatmap (OpenStreetMap) ────────────────────────
class _HeatmapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: 'open')
            .snapshots(),
        builder: (_, snap) {
          final reports = snap.data?.docs ?? [];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(28.4744, 77.5040),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.shashvat.spotseva_dashboard',
                ),
                // Heatmap circles
                CircleLayer(
                  circles: reports.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final gp = d['geopoint'] as GeoPoint?;
                    if (gp == null) {
                      return CircleMarker(
                          point: const LatLng(0, 0), radius: 0);
                    }
                    final severity = d['severity'] as String? ?? 'low';
                    final color = severity == 'high'
                        ? const Color(0xFFA32D2D)
                        : severity == 'medium'
                            ? const Color(0xFF854F0B)
                            : const Color(0xFF2E7D52);
                    return CircleMarker(
                      point: LatLng(gp.latitude, gp.longitude),
                      radius: 40,
                      useRadiusInMeter: true,
                      color: color.withOpacity(0.35),
                      borderStrokeWidth: 2,
                      borderColor: color.withOpacity(0.8),
                    );
                  }).toList(),
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Priority Queue ────────────────────────────────────────────
class _PriorityQueue extends StatefulWidget {
  @override
  State<_PriorityQueue> createState() => _PriorityQueueState();
}

class _PriorityQueueState extends State<_PriorityQueue> {
  String? _selectedReportId;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Priority Queue',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('status', isEqualTo: 'open')
                  .orderBy('severity', descending: true)
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (_, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('✅ No open reports',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final severity =
                        d['severity'] as String? ?? 'low';
                    final color = severity == 'high'
                        ? const Color(0xFFA32D2D)
                        : severity == 'medium'
                            ? const Color(0xFF854F0B)
                            : const Color(0xFF2E7D52);
                    final ts = d['createdAt'] as Timestamp?;
                    final timeStr = ts != null
                        ? timeago.format(ts.toDate())
                        : '';
                    return InkWell(
                      onTap: () => setState(
                          () => _selectedReportId = docs[i].id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedReportId == docs[i].id
                              ? Colors.white.withOpacity(0.05)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withOpacity(0.06)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['aiLabel'] as String? ??
                                        d['issueType'] as String? ??
                                        'Issue',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(timeStr,
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: TextStyle(
                                    color: color, fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Activity Feed ─────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('checkins')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final ts = d['timestamp'] as Timestamp?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Text('✅',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Check-in at spot ${(d['spotId'] as String).substring(0, 8)}…',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                        ),
                        Text(
                          ts != null
                              ? timeago.format(ts.toDate())
                              : '',
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
