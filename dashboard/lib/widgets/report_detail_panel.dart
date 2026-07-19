import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/status_badge.dart';

class ReportDetailPanel extends StatefulWidget {
  final String reportId;
  const ReportDetailPanel({super.key, required this.reportId});

  @override
  State<ReportDetailPanel> createState() => _ReportDetailPanelState();
}

class _ReportDetailPanelState extends State<ReportDetailPanel> {
  final _workerController = TextEditingController();
  bool _updating = false;

  Future<void> _updateStatus(
      String newStatus, Map<String, dynamic> data) async {
    setState(() => _updating = true);
    try {
      final update = <String, dynamic>{
        'status': newStatus,
        'assignedTo': _workerController.text.trim(),
      };
      if (newStatus == 'resolved') {
        update['resolvedAt'] = FieldValue.serverTimestamp();
      }
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update(update);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Status updated to $newStatus'),
              backgroundColor: const Color(0xFF2E7D52)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: const Color(0xFF993C1D)),
        );
      }
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF141821),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.reportId)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
                child: CircularProgressIndicator());
          }
          final d = snap.data!.data() as Map<String, dynamic>;
          final photoUrls = (d['photoUrls'] as List<dynamic>?) ?? [];
          final severity = d['severity'] as String? ?? 'low';
          final status = d['status'] as String? ?? 'open';
          final assignedTo = d['assignedTo'] as String? ?? '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Report Details',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const Spacer(),
                    StatusBadge(status: status),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── AI Label & Severity ──────────────────
                    _InfoRow('AI Classification',
                        d['aiLabel'] as String? ?? '—'),
                    _InfoRow('Issue Type',
                        d['issueType'] as String? ?? '—'),
                    _InfoRow('Severity',
                        severity.toUpperCase(),
                        valueColor: severity == 'high'
                            ? const Color(0xFFA32D2D)
                            : severity == 'medium'
                                ? const Color(0xFFAA6C00)
                                : const Color(0xFF2E7D52)),
                    _InfoRow('Spot ID',
                        (d['spotId'] as String? ?? '—')
                            .substring(0, 12) +
                            '…'),

                    const SizedBox(height: 12),

                    // ── Description ──────────────────────────
                    if ((d['description'] as String?)?.isNotEmpty ==
                        true) ...[
                      const Text('Description',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(d['description'] as String,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13,
                              height: 1.5)),
                      const SizedBox(height: 12),
                    ],

                    // ── Photos ───────────────────────────────
                    if (photoUrls.isNotEmpty) ...[
                      const Text('Photos',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: photoUrls.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(8),
                              child: Image.network(
                                photoUrls[i] as String,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Assign worker ─────────────────────────
                    const Text('Assign Field Worker',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _workerController
                        ..text = assignedTo,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Worker name or ID',
                        hintStyle: const TextStyle(
                            color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E2330),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Status Actions ────────────────────────
                    const Text('Update Status',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 8),
                    if (_updating)
                      const Center(child: CircularProgressIndicator())
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ActionButton(
                            label: 'In Progress',
                            color: const Color(0xFFAA6C00),
                            onTap: () =>
                                _updateStatus('inProgress', d),
                            enabled: status == 'open',
                          ),
                          _ActionButton(
                            label: '✅ Resolve',
                            color: const Color(0xFF2E7D52),
                            onTap: () =>
                                _updateStatus('resolved', d),
                            enabled: status != 'resolved',
                          ),
                          _ActionButton(
                            label: 'Reject',
                            color: const Color(0xFF4A4A4A),
                            onTap: () =>
                                _updateStatus('rejected', d),
                            enabled: status == 'open',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}
