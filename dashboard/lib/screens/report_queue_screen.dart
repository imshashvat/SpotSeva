import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/report_detail_panel.dart';
import '../widgets/status_badge.dart';

class ReportQueueScreen extends StatefulWidget {
  const ReportQueueScreen({super.key});

  @override
  State<ReportQueueScreen> createState() => _ReportQueueScreenState();
}

class _ReportQueueScreenState extends State<ReportQueueScreen> {
  String _statusFilter = 'all';
  String _severityFilter = 'all';
  String? _selectedReportId;

  Stream<QuerySnapshot> get _stream {
    var q = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (_statusFilter != 'all') {
      q = FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: _statusFilter)
          .orderBy('createdAt', descending: true)
          .limit(100);
    }
    if (_severityFilter != 'all') {
      q = FirebaseFirestore.instance
          .collection('reports')
          .where('severity', isEqualTo: _severityFilter)
          .orderBy('createdAt', descending: true)
          .limit(100);
    }

    return q.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Report List ──────────────────────────────────────
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterBar(
                statusFilter: _statusFilter,
                severityFilter: _severityFilter,
                onStatusChanged: (v) => setState(() {
                  _statusFilter = v;
                  _selectedReportId = null;
                }),
                onSeverityChanged: (v) => setState(() {
                  _severityFilter = v;
                  _selectedReportId = null;
                }),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _stream,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                          child: Text('No reports found',
                              style: TextStyle(color: Colors.white38)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final d = doc.data() as Map<String, dynamic>;
                        return _ReportRow(
                          doc: doc,
                          data: d,
                          isSelected: _selectedReportId == doc.id,
                          onTap: () => setState(
                              () => _selectedReportId = doc.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Detail Panel ─────────────────────────────────────
        if (_selectedReportId != null)
          SizedBox(
            width: 380,
            child: ReportDetailPanel(reportId: _selectedReportId!),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String statusFilter, severityFilter;
  final ValueChanged<String> onStatusChanged, onSeverityChanged;

  const _FilterBar({
    required this.statusFilter,
    required this.severityFilter,
    required this.onStatusChanged,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF141821),
      child: Row(
        children: [
          const Text('Report Queue',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(width: 24),
          _DropFilter(
            label: 'Status',
            value: statusFilter,
            options: const [
              'all', 'open', 'inProgress', 'resolved', 'rejected'
            ],
            onChanged: onStatusChanged,
          ),
          const SizedBox(width: 12),
          _DropFilter(
            label: 'Severity',
            value: severityFilter,
            options: const ['all', 'high', 'medium', 'low'],
            onChanged: onSeverityChanged,
          ),
        ],
      ),
    );
  }
}

class _DropFilter extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1E2330),
        style:
            const TextStyle(color: Colors.white70, fontSize: 12),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportRow({
    required this.doc,
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final severity = data['severity'] as String? ?? 'low';
    final status = data['status'] as String? ?? 'open';
    final aiLabel = data['aiLabel'] as String? ?? data['issueType'] as String? ?? 'Issue';
    final ts = data['createdAt'] as Timestamp?;
    final photoUrls = (data['photoUrls'] as List<dynamic>?) ?? [];
    final color = severity == 'high'
        ? const Color(0xFFA32D2D)
        : severity == 'medium'
            ? const Color(0xFFAA6C00)
            : const Color(0xFF2E7D52);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F6E56).withOpacity(0.1)
              : const Color(0xFF1E2330),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFF0F6E56), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Thumbnail
            if (photoUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  photoUrls.first as String,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: Colors.grey[800],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white24, size: 18),
                  ),
                ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.report_outlined,
                    color: Colors.white38, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aiLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    ts != null ? timeago.format(ts.toDate()) : '',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: status),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
