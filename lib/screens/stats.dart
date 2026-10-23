import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/services/game_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const List<String> _categories = ['Study', 'Work', 'Sport', 'Personal'];
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _tile(String emoji, String value, String label) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bars(BuildContext context, List<int> counts, List<String> labels) {
    var maxValue = 1;
    for (final c in counts) {
      if (c > maxValue) maxValue = c;
    }
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < counts.length; i++)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${counts[i]}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  width: 26,
                  height: counts[i] == 0 ? 4 : 100.0 * counts[i] / maxValue,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i], style: const TextStyle(fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0066cc),
        foregroundColor: Colors.white,
        elevation: 13,
        title: const Text('Statistics', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: userRef.collection('tasks').snapshots(),
          builder: (context, taskSnap) {
            if (taskSnap.hasError) {
              return const Center(child: Text('Could not load statistics'));
            }
            if (!taskSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = taskSnap.data!.docs.map((d) => d.data()).toList();
            final now = DateTime.now();

            var done = 0;
            var overdue = 0;
            final catTotal = {for (final c in _categories) c: 0};
            final catDone = {for (final c in _categories) c: 0};

            for (final t in docs) {
              final isDone = t['isDone'] == true;
              final due = (t['dueAt'] as Timestamp?)?.toDate();
              if (isDone) done++;
              if (!isDone && due != null && due.isBefore(now)) overdue++;
              final cat = t['category'] as String?;
              if (cat != null && catTotal.containsKey(cat)) {
                catTotal[cat] = catTotal[cat]! + 1;
                if (isDone) catDone[cat] = catDone[cat]! + 1;
              }
            }

            // last 7 days (oldest -> today)
            final counts = <int>[];
            final labels = <String>[];
            for (var i = 6; i >= 0; i--) {
              final day = DateTime(now.year, now.month, now.day - i);
              var c = 0;
              for (final t in docs) {
                final at = (t['completedAt'] as Timestamp?)?.toDate();
                if (t['isDone'] == true && at != null && _sameDay(at, day)) {
                  c++;
                }
              }
              counts.add(c);
              labels.add(_days[day.weekday - 1]);
            }

            final percent =
                docs.isEmpty ? 0 : (done * 100 / docs.length).round();

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userRef.snapshots(),
              builder: (context, userSnap) {
                final u = userSnap.data?.data() ?? <String, dynamic>{};
                final xp = (u['xp'] as num?)?.toInt() ?? 0;
                final best = (u['bestStreak'] as num?)?.toInt() ?? 0;
                final focus = (u['focusSessions'] as num?)?.toInt() ?? 0;

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _tile('⭐', '${GameService.levelForXp(xp)}', 'Level'),
                        _tile('✨', '$xp', 'Total XP'),
                        _tile('🔥', '${GameService.effectiveStreak(u)}',
                            'Current streak'),
                        _tile('🏅', '$best', 'Best streak'),
                        _tile('✅', '$done / ${docs.length}', 'Tasks done'),
                        _tile('🎯', '$focus', 'Focus sessions'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Completion rate: $percent%',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 10,
                      ),
                    ),
                    if (overdue > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('$overdue overdue task(s)'),
                      ),
                    const SizedBox(height: 24),
                    const Text('Completed in the last 7 days',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _bars(context, counts, labels),
                    const SizedBox(height: 24),
                    const Text('By category',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final c in _categories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$c  (${catDone[c]} / ${catTotal[c]})'),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: catTotal[c] == 0
                                    ? 0
                                    : catDone[c]! / catTotal[c]!,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
