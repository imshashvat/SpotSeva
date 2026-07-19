import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class CitizensScreen extends StatefulWidget {
  const CitizensScreen({super.key});

  @override
  State<CitizensScreen> createState() => _CitizensScreenState();
}

class _CitizensScreenState extends State<CitizensScreen> {
  String _sort = 'allTimePoints';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              const Text('Citizens',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 20),
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name…',
                    hintStyle: const TextStyle(
                        color: Colors.white30, fontSize: 12),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white30, size: 16),
                    filled: true,
                    fillColor: const Color(0xFF1E2330),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sort,
                  dropdownColor: const Color(0xFF1E2330),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                  items: const [
                    DropdownMenuItem(
                        value: 'allTimePoints',
                        child: Text('By All-Time Points')),
                    DropdownMenuItem(
                        value: 'weekPoints',
                        child: Text('By Week Points')),
                    DropdownMenuItem(
                        value: 'monthPoints',
                        child: Text('By Month Points')),
                  ],
                  onChanged: (v) => setState(() => _sort = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Table header ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141821),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                SizedBox(width: 30),
                Expanded(
                    flex: 3, child: _Hdr('Citizen')),
                Expanded(child: _Hdr('Points')),
                Expanded(child: _Hdr('Reports')),
                Expanded(child: _Hdr('Check-ins')),
                Expanded(child: _Hdr('Badges')),
                Expanded(child: _Hdr('Status')),
                SizedBox(width: 60),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Citizens list ─────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaderboard')
                  .orderBy(_sort, descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (_, lbSnap) {
                var docs = lbSnap.data?.docs ?? [];

                // Client-side search filter
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final name = ((d.data() as Map)['displayName'] as String?)
                            ?.toLowerCase() ??
                        '';
                    return name.contains(_search.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No citizens found',
                        style: TextStyle(color: Colors.white38)),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _CitizenRow(
                    rank: i + 1,
                    userId: docs[i].id,
                    lbData: docs[i].data() as Map<String, dynamic>,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _CitizenRow extends StatelessWidget {
  final int rank;
  final String userId;
  final Map<String, dynamic> lbData;
  const _CitizenRow({
    required this.rank,
    required this.userId,
    required this.lbData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId)
          .get(),
      builder: (_, snap) {
        final wallet =
            snap.data?.data() as Map<String, dynamic>? ?? {};
        final flagged = wallet['flagged'] as bool? ?? false;
        final totalReports = wallet['totalReports'] as int? ?? 0;
        final totalCheckins = wallet['totalCheckins'] as int? ?? 0;
        final badges = (wallet['badges'] as List<dynamic>?) ?? [];
        final allTimePoints =
            lbData['allTimePoints'] as int? ?? 0;
        final displayName =
            lbData['displayName'] as String? ?? 'User';

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: flagged
                ? const Color(0xFF3A1515)
                : const Color(0xFF1E2330),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('#$rank',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          const Color(0xFF0F6E56).withOpacity(0.3),
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF82CFB5), fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(displayName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text('$allTimePoints',
                    style: const TextStyle(
                        color: Color(0xFF82CFB5), fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text('$totalReports',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ),
              Expanded(
                child: Text('$totalCheckins',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ),
              Expanded(
                child: Text('${badges.length}🏅',
                    style: const TextStyle(fontSize: 11)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: flagged
                        ? const Color(0xFFA32D2D).withOpacity(0.2)
                        : const Color(0xFF2E7D52).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    flagged ? '🚩 Flagged' : '✅ Active',
                    style: TextStyle(
                        color: flagged
                            ? const Color(0xFFA32D2D)
                            : const Color(0xFF2E7D52),
                        fontSize: 9),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Row(
                  children: [
                    if (flagged)
                      IconButton(
                        icon: const Icon(Icons.flag_outlined,
                            size: 14, color: Color(0xFFA32D2D)),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('wallets')
                              .doc(userId)
                              .update({'flagged': false, 'flagReason': ''});
                        },
                        tooltip: 'Unflag',
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Hdr extends StatelessWidget {
  final String label;
  const _Hdr(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }
}
