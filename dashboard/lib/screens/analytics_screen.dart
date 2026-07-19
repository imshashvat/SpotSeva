import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ReportsBarChart()),
              const SizedBox(width: 16),
              Expanded(child: _SeverityPieChart()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _CheckinLineChart()),
              const SizedBox(width: 16),
              Expanded(child: _TopSpotsList()),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reports per day bar chart ──────────────────────────────────
class _ReportsBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Reports This Week',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('createdAt',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 7))))
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];

          // Group by day
          final byDay = List<double>.filled(7, 0);
          for (final doc in docs) {
            final ts = (doc.data() as Map)['createdAt'] as Timestamp?;
            if (ts != null) {
              final diff = DateTime.now()
                  .difference(ts.toDate())
                  .inDays;
              if (diff < 7) byDay[6 - diff]++;
            }
          }

          return BarChart(
            BarChartData(
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final day = DateTime.now()
                          .subtract(Duration(days: 6 - v.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('E').format(day),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 9),
                            ))),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
                getDrawingVerticalLine: (_) => FlLine(
                    color: Colors.transparent),
              ),
              barGroups: byDay.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: const Color(0xFF0F6E56),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// ── Severity pie chart ─────────────────────────────────────────
class _SeverityPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Issue Severity Breakdown',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: 'open')
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          int high = 0, medium = 0, low = 0;
          for (final doc in docs) {
            final sev = (doc.data() as Map)['severity'] as String? ?? 'low';
            if (sev == 'high') high++;
            else if (sev == 'medium') medium++;
            else low++;
          }
          final total = high + medium + low;
          if (total == 0) {
            return const Center(
                child: Text('No open reports',
                    style: TextStyle(color: Colors.white38)));
          }
          return PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                if (high > 0)
                  _slice('High', high, total, const Color(0xFFA32D2D)),
                if (medium > 0)
                  _slice('Med', medium, total, const Color(0xFFAA6C00)),
                if (low > 0)
                  _slice('Low', low, total, const Color(0xFF2E7D52)),
              ],
            ),
          );
        },
      ),
    );
  }

  PieChartSectionData _slice(
      String title, int count, int total, Color color) {
    final pct = (count / total * 100).round();
    return PieChartSectionData(
      color: color,
      value: count.toDouble(),
      title: '$title\n$pct%',
      titleStyle: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      radius: 70,
    );
  }
}

// ── Check-in line chart ────────────────────────────────────────
class _CheckinLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Check-ins This Week',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('checkins')
            .where('timestamp',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 7))))
            .where('valid', isEqualTo: true)
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          final byDay = List<double>.filled(7, 0);
          for (final doc in docs) {
            final ts = (doc.data() as Map)['timestamp'] as Timestamp?;
            if (ts != null) {
              final diff =
                  DateTime.now().difference(ts.toDate()).inDays;
              if (diff < 7) byDay[6 - diff]++;
            }
          }
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
                getDrawingVerticalLine: (_) =>
                    FlLine(color: Colors.transparent),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final day = DateTime.now()
                          .subtract(Duration(days: 6 - v.toInt()));
                      return Text(DateFormat('E').format(day),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 9),
                            ))),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: byDay.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFF82CFB5),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF82CFB5),
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF0F6E56).withOpacity(0.12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Top active spots ──────────────────────────────────────────
class _TopSpotsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Top Active Spots',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('spots')
            .orderBy('checkinsCount', descending: true)
            .limit(8)
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final name = d['name'] as String? ?? 'Spot';
              final count = d['checkinsCount'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text('${i + 1}.',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name.length > 30
                            ? '${name.substring(0, 30)}…'
                            : name,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F6E56).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('$count ✅',
                          style: const TextStyle(
                              color: Color(0xFF82CFB5), fontSize: 10)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
