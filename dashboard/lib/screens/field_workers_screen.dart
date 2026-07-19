import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FieldWorkersScreen extends StatefulWidget {
  const FieldWorkersScreen({super.key});

  @override
  State<FieldWorkersScreen> createState() => _FieldWorkersScreenState();
}

class _FieldWorkersScreenState extends State<FieldWorkersScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Workers List ─────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Field Workers',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'field_worker')
                        .snapshots(),
                    builder: (_, snap) {
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No field workers added yet.\nAdd one using the form →',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return _WorkerCard(doc: docs[i], data: d);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // ── Add Worker Form ──────────────────────────────
          SizedBox(
            width: 320,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2330),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add Field Worker',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 16),
                  _DarkTextField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    hint: 'e.g. Ramesh Kumar',
                  ),
                  const SizedBox(height: 12),
                  _DarkTextField(
                    controller: _phoneCtrl,
                    label: 'Phone / Email',
                    hint: '+91 9876543210',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _adding ? null : _addWorker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6E56),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _adding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Add Worker'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addWorker() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _adding = true);
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'displayName': _nameCtrl.text.trim(),
        'email': _phoneCtrl.text.trim(),
        'role': 'field_worker',
        'ward': 'Ward 14',
        'isActive': true,
        'assignedReports': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _nameCtrl.clear();
      _phoneCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _adding = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}

class _WorkerCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  const _WorkerCard({required this.doc, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['displayName'] as String? ?? 'Worker';
    final email = data['email'] as String? ?? '';
    final assigned = data['assignedReports'] as int? ?? 0;
    final active = data['isActive'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF0F6E56).withOpacity(0.3),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF82CFB5), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(email,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$assigned assigned',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF2E7D52)
                        : Colors.grey,
                    shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Colors.white24),
            onPressed: () => doc.reference.delete(),
          ),
        ],
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF0F1117),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
