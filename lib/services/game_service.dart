import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  const Achievement(this.id, this.emoji, this.title, this.description);
}

class GameResult {
  final int xpGained;
  final int level;
  final bool leveledUp;
  final int streak;
  final List<String> newAchievements;
  const GameResult({
    required this.xpGained,
    required this.level,
    required this.leveledUp,
    required this.streak,
    required this.newAchievements,
  });
}

/// XP, levels, streak and achievements. Everything is stored in the
/// user document: users/{uid}
class GameService {
  static const List<Achievement> achievements = [
    Achievement('first_task', '🌱', 'First step', 'Complete your first task'),
    Achievement('ten_tasks', '💪', 'On a roll', 'Complete 10 tasks'),
    Achievement('fifty_tasks', '🏆', 'Task master', 'Complete 50 tasks'),
    Achievement('streak_3', '🔥', 'Warming up', 'Reach a 3-day streak'),
    Achievement('streak_7', '⚡', 'Unstoppable', 'Reach a 7-day streak'),
    Achievement(
        'early_bird', '🌅', 'Early bird', 'Complete a task before 8 AM'),
    Achievement('first_focus', '🎯', 'Focused', 'Finish a focus session'),
    Achievement('focus_5', '🧠', 'Deep work', 'Finish 5 focus sessions'),
    Achievement('level_5', '⭐', 'Rising star', 'Reach level 5'),
  ];

  static Achievement? byId(String id) {
    for (final a in achievements) {
      if (a.id == id) return a;
    }
    return null;
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _int(Map<String, dynamic> data, String key) =>
      (data[key] as num?)?.toInt() ?? 0;

  /// 100 XP per level
  static int levelForXp(int xp) => xp ~/ 100 + 1;

  /// The streak only counts if the last completed task was today or yesterday.
  static int effectiveStreak(Map<String, dynamic> data) {
    final last = data['lastCompletedDate'] as String?;
    if (last == null) return 0;
    final now = DateTime.now();
    final today = dateKey(now);
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    if (last == today || last == yesterday) return _int(data, 'streak');
    return 0;
  }

  static Future<GameResult> taskCompleted(
    String uid, {
    required String priority,
    required bool onTime,
  }) {
    const base = {'Low': 10, 'Medium': 20, 'High': 30};
    final xp = (base[priority] ?? 10) + (onTime ? 5 : 0);
    return _apply(
      uid,
      xp: xp,
      tasks: 1,
      updateStreak: true,
      earlyBird: DateTime.now().hour < 8,
    );
  }

  static Future<GameResult> focusDone(String uid) =>
      _apply(uid, xp: 15, focus: 1);

  static Future<GameResult> _apply(
    String uid, {
    required int xp,
    int tasks = 0,
    int focus = 0,
    bool updateStreak = false,
    bool earlyBird = false,
  }) {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    return FirebaseFirestore.instance.runTransaction<GameResult>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final oldXp = _int(data, 'xp');
      final newXp = oldXp + xp;
      final oldLevel = levelForXp(oldXp);
      final newLevel = levelForXp(newXp);

      var streak = _int(data, 'streak');
      var best = _int(data, 'bestStreak');
      var last = data['lastCompletedDate'] as String?;
      if (updateStreak) {
        final now = DateTime.now();
        final today = dateKey(now);
        if (last != today) {
          final yesterday = dateKey(now.subtract(const Duration(days: 1)));
          streak = (last == yesterday) ? streak + 1 : 1;
          last = today;
        }
      }
      if (streak > best) best = streak;

      final totalDone = _int(data, 'totalCompleted') + tasks;
      final focusTotal = _int(data, 'focusSessions') + focus;

      final have = List<String>.from((data['achievements'] as List?) ?? []);
      final earned = <String>[
        if (totalDone >= 1) 'first_task',
        if (totalDone >= 10) 'ten_tasks',
        if (totalDone >= 50) 'fifty_tasks',
        if (streak >= 3) 'streak_3',
        if (streak >= 7) 'streak_7',
        if (earlyBird) 'early_bird',
        if (focusTotal >= 1) 'first_focus',
        if (focusTotal >= 5) 'focus_5',
        if (newLevel >= 5) 'level_5',
      ];
      final fresh = earned.where((id) => !have.contains(id)).toList();

      tx.set(
        ref,
        {
          'xp': newXp,
          'level': newLevel,
          'streak': streak,
          'bestStreak': best,
          'lastCompletedDate': last,
          'totalCompleted': totalDone,
          'focusSessions': focusTotal,
          'achievements': [...have, ...fresh],
        },
        SetOptions(merge: true),
      );

      return GameResult(
        xpGained: xp,
        level: newLevel,
        leveledUp: newLevel > oldLevel,
        streak: streak,
        newAchievements: fresh,
      );
    });
  }
}
