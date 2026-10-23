import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/services/game_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0066cc),
        foregroundColor: Colors.white,
        elevation: 13,
        title:
            const Text('Achievements', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('Could not load achievements'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!.data() ?? <String, dynamic>{};
            final unlocked =
                List<String>.from((data['achievements'] as List?) ?? []);

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '${unlocked.length} / ${GameService.achievements.length} unlocked',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ...GameService.achievements.map((a) {
                  final done = unlocked.contains(a.id);
                  return Opacity(
                    opacity: done ? 1 : 0.45,
                    child: Card(
                      child: ListTile(
                        leading:
                            Text(a.emoji, style: const TextStyle(fontSize: 32)),
                        title: Text(a.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(a.description),
                        trailing: Icon(done ? Icons.check_circle : Icons.lock,
                            color: done ? Colors.green : null),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
