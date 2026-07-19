import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/status_badge.dart';

class SpotManagerScreen extends StatefulWidget {
  const SpotManagerScreen({super.key});

  @override
  State<SpotManagerScreen> createState() => _SpotManagerScreenState();
}

class _SpotManagerScreenState extends State<SpotManagerScreen> {
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _adding = false;
  String _filter = 'all';

  String _geohash(double lat, double lng, int precision) {
    const base32 = "0123456789bcdefghjkmnpqrstuvwxyz";
    double minLat = -90.0, maxLat = 90.0;
    double minLng = -180.0, maxLng = 180.0;
    String hash = '';
    int bits = 0, hashValue = 0;
    bool isEven = true;
    while (hash.length < precision) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) { hashValue = (hashValue << 1) | 1; minLng = mid; }
        else { hashValue <<= 1; maxLng = mid; }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) { hashValue = (hashValue << 1) | 1; minLat = mid; }
        else { hashValue <<= 1; maxLat = mid; }
      }
      isEven = !isEven;
      bits++;
      if (bits == 5) {
        hash += base32[hashValue];
        bits = 0;
        hashValue = 0;
      }
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Spot List ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Spot Manager',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        dropdownColor: const Color(0xFF1E2330),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'adopted', child: Text('Adopted')),
                          DropdownMenuItem(value: 'clean', child: Text('Clean')),
                          DropdownMenuItem(value: 'issue', child: Text('Issue')),
                          DropdownMenuItem(value: 'critical', child: Text('Critical')),
                        ],
                        onChanged: (v) => setState(() => _filter = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _filter == 'all'
                        ? FirebaseFirestore.instance
                            .collection('spots')
                            .orderBy('createdAt', descending: true)
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('spots')
                            .where('status', isEqualTo: _filter)
                            .snapshots(),
                    builder: (_, snap) {
                      final docs = snap.data?.docs ?? [];
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          return _SpotRow(doc: docs[i], data: d);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // ── Add Spot Form ────────────────────────────────
          SizedBox(
            width: 300,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2330),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Spot',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 16),
                  _Field(_nameCtrl, 'Spot Name', 'e.g. Sector 12 Bench Row'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _Field(_latCtrl, 'Latitude', '28.4712')),
                    const SizedBox(width: 8),
                    Expanded(child: _Field(_lngCtrl, 'Longitude', '77.5038')),
                  ]),
                  const SizedBox(height: 10),
                  _Field(_categoryCtrl, 'Category', 'Park Furniture'),
                  const SizedBox(height: 10),
                  _Field(_descCtrl, 'Description', 'Brief description…'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _adding ? null : _addSpot,
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
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Add Spot'),
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

  Future<void> _addSpot() async {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (_nameCtrl.text.isEmpty || lat == null || lng == null) return;
    setState(() => _adding = true);
    try {
      final gh = _geohash(lat, lng, 5);
      await FirebaseFirestore.instance.collection('spots').add({
        'name': _nameCtrl.text.trim(),
        'geopoint': GeoPoint(lat, lng),
        'geohash': gh,
        'category': _categoryCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'status': 'clean',
        'adopterId': '',
        'checkinsCount': 0,
        'isActive': true,
        'ward': 'Ward 14',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'municipal',
      });
      _nameCtrl.clear(); _latCtrl.clear(); _lngCtrl.clear();
      _categoryCtrl.clear(); _descCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
    setState(() => _adding = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _latCtrl.dispose(); _lngCtrl.dispose();
    _categoryCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }
}

class _SpotRow extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  const _SpotRow({required this.doc, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Unnamed Spot';
    final status = data['status'] as String? ?? 'clean';
    final checkins = data['checkinsCount'] as int? ?? 0;
    final adopted = (data['adopterId'] as String?)?.isNotEmpty == true;
    final category = data['category'] as String? ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2330),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text(category,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Text('$checkins ✅',
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(width: 10),
          StatusBadge(status: status),
          if (adopted) ...[
            const SizedBox(width: 6),
            const Text('📌',
                style: TextStyle(fontSize: 12)),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.white24),
            onPressed: () => doc.reference.update({'isActive': false}),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  const _Field(this.controller, this.label, this.hint);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            filled: true, fillColor: const Color(0xFF0F1117),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 9),
          ),
        ),
      ],
    );
  }
}
