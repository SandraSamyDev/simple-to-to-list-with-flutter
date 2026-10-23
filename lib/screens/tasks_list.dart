import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/screens/focus_timer.dart';
import 'package:to_do_list/screens/new_task.dart';
import 'package:to_do_list/screens/settings.dart';
import 'package:to_do_list/services/game_service.dart';
import 'package:to_do_list/services/notification_service.dart';

typedef TaskDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

enum TaskFilter { all, today, upcoming, overdue, done }

class TasksList extends StatefulWidget {
  const TasksList({super.key});

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  static const Map<TaskFilter, String> _filterLabels = {
    TaskFilter.all: 'All',
    TaskFilter.today: 'Today',
    TaskFilter.upcoming: 'Upcoming',
    TaskFilter.overdue: 'Overdue',
    TaskFilter.done: 'Done',
  };

  late final String _uid;
  late final CollectionReference<Map<String, dynamic>> _tasks;
  late final ConfettiController _confetti;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  TaskFilter _filter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _tasks = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('tasks');
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _info(String title, String text) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n, d.hour, d.minute);

  int _newNotifId() => DateTime.now().microsecondsSinceEpoch % 2000000000;

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDue(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';

  Color _priorityColor(String? p) {
    switch (p) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _categoryIcon(String? c) {
    switch (c) {
      case 'Study':
        return Icons.menu_book;
      case 'Work':
        return Icons.work;
      case 'Sport':
        return Icons.fitness_center;
      default:
        return Icons.person;
    }
  }

  // ---------------------------------------------------------- notifications

  Future<void> _scheduleReminder(
    int notifId,
    String title,
    DateTime? due,
    int reminderMinutes,
  ) async {
    await NotificationService.instance.cancel(notifId);
    if (due == null || reminderMinutes < 0) return;

    final now = DateTime.now();
    var when = due.subtract(Duration(minutes: reminderMinutes));
    // reminder time already passed but the task is still ahead: remind at due time
    if (!when.isAfter(now) && due.isAfter(now)) when = due;

    await NotificationService.instance.schedule(
      id: notifId,
      title: 'Task reminder',
      body: reminderMinutes == 0 ? '$title is due now' : '$title is due soon',
      when: when,
    );
  }

  // ---------------------------------------------------------------- actions

  Future<void> _addTask() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const NewTask()),
    );
    if (result == null) return;

    final due = result['dueAt'] as DateTime?;
    final reminder = result['reminderMinutes'] as int;
    final notifId = _newNotifId();

    await _scheduleReminder(notifId, result['title'] as String, due, reminder);
    try {
      await _tasks.add({
        'title': result['title'],
        'description': result['description'],
        'category': result['category'],
        'priority': result['priority'],
        'dueAt': due == null ? null : Timestamp.fromDate(due),
        'repeat': result['repeat'],
        'reminderMinutes': reminder,
        'notifId': notifId,
        'isDone': false,
        'xpAwarded': false,
        'repeatSpawned': false,
        'completedAt': null,
        'createdAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      await NotificationService.instance.cancel(notifId);
      if (mounted) _showMessage('Could not save the task (${e.code})');
    }
  }

  Future<void> _editTask(TaskDoc doc) async {
    final data = doc.data();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => NewTask(initial: data)),
    );
    if (result == null) return;

    final due = result['dueAt'] as DateTime?;
    final reminder = result['reminderMinutes'] as int;
    final notifId = (data['notifId'] as num?)?.toInt() ?? _newNotifId();
    final isDone = data['isDone'] == true;

    if (isDone) {
      await NotificationService.instance.cancel(notifId);
    } else {
      await _scheduleReminder(
          notifId, result['title'] as String, due, reminder);
    }

    try {
      await doc.reference.update({
        'title': result['title'],
        'description': result['description'],
        'category': result['category'],
        'priority': result['priority'],
        'dueAt': due == null ? null : Timestamp.fromDate(due),
        'repeat': result['repeat'],
        'reminderMinutes': reminder,
        'notifId': notifId,
      });
    } on FirebaseException catch (e) {
      if (mounted) _showMessage('Could not update the task (${e.code})');
    }
  }

  Future<void> _deleteTask(TaskDoc doc) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true) return;

    final notifId = (doc.data()['notifId'] as num?)?.toInt();
    if (notifId != null) await NotificationService.instance.cancel(notifId);
    try {
      await doc.reference.delete();
    } on FirebaseException catch (e) {
      if (mounted) _showMessage('Could not delete the task (${e.code})');
    }
  }

  Future<void> _toggleDone(TaskDoc doc, bool done) async {
    final data = doc.data();
    final notifId = (data['notifId'] as num?)?.toInt();
    final due = (data['dueAt'] as Timestamp?)?.toDate();

    try {
      await doc.reference.update({
        'isDone': done,
        'completedAt': done ? Timestamp.now() : null,
      });
    } on FirebaseException catch (e) {
      if (mounted) _showMessage('Could not update the task (${e.code})');
      return;
    }

    // un-checking: bring the reminder back (if it is still in the future)
    if (!done) {
      if (notifId != null && due != null) {
        await _scheduleReminder(
          notifId,
          (data['title'] ?? '') as String,
          due,
          (data['reminderMinutes'] as num?)?.toInt() ?? -1,
        );
      }
      return;
    }

    if (notifId != null) await NotificationService.instance.cancel(notifId);
    _confetti.play();

    // XP is given only once per task, so ticking/unticking can't farm points
    if (data['xpAwarded'] != true) {
      final onTime = due == null || !DateTime.now().isAfter(due);
      try {
        final res = await GameService.taskCompleted(
          _uid,
          priority: (data['priority'] ?? 'Medium') as String,
          onTime: onTime,
        );
        await doc.reference.update({'xpAwarded': true});

        if (!mounted) return;
        _showMessage(
            '+${res.xpGained} XP${res.streak > 1 ? '   🔥 ${res.streak} days' : ''}');
        if (res.leveledUp) {
          await _info('Level up! 🎉', 'You reached level ${res.level}');
        }
        for (final id in res.newAchievements) {
          final a = GameService.byId(id);
          if (a == null || !mounted) continue;
          await _info('Achievement unlocked ${a.emoji}', a.title);
        }
      } on FirebaseException catch (e) {
        if (mounted) _showMessage('Could not save your points (${e.code})');
      }
    }

    await _spawnNextOccurrence(doc);
  }

  /// Repeating tasks: when one is completed, create the next one.
  Future<void> _spawnNextOccurrence(TaskDoc doc) async {
    final data = doc.data();
    final due = (data['dueAt'] as Timestamp?)?.toDate();
    final repeat = (data['repeat'] ?? 'none') as String;
    if (due == null || repeat == 'none' || data['repeatSpawned'] == true) {
      return;
    }

    final step = repeat == 'weekly' ? 7 : 1;
    final now = DateTime.now();
    var next = _addDays(due, step);
    var guard = 0;
    while (next.isBefore(now) && guard < 400) {
      next = _addDays(next, step);
      guard++;
    }

    final reminder = (data['reminderMinutes'] as num?)?.toInt() ?? -1;
    final notifId = _newNotifId();
    try {
      await doc.reference.update({'repeatSpawned': true});
      await _scheduleReminder(
          notifId, (data['title'] ?? '') as String, next, reminder);
      await _tasks.add({
        'title': data['title'],
        'description': data['description'],
        'category': data['category'],
        'priority': data['priority'],
        'dueAt': Timestamp.fromDate(next),
        'repeat': repeat,
        'reminderMinutes': reminder,
        'notifId': notifId,
        'isDone': false,
        'xpAwarded': false,
        'repeatSpawned': false,
        'completedAt': null,
        'createdAt': Timestamp.now(),
      });
    } on FirebaseException catch (e) {
      if (mounted) _showMessage('Could not create the next task (${e.code})');
    }
  }

  // -------------------------------------------------------------- filtering

  List<TaskDoc> _applyFilters(List<TaskDoc> all) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final q = _query.trim().toLowerCase();

    final list = all.where((doc) {
      final d = doc.data();
      final isDone = d['isDone'] == true;
      final due = (d['dueAt'] as Timestamp?)?.toDate();

      if (q.isNotEmpty) {
        final text =
            '${d['title'] ?? ''} ${d['description'] ?? ''}'.toLowerCase();
        if (!text.contains(q)) return false;
      }

      switch (_filter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.today:
          return due != null && _sameDay(due, now);
        case TaskFilter.upcoming:
          return !isDone && due != null && due.isAfter(endOfToday);
        case TaskFilter.overdue:
          return !isDone && due != null && due.isBefore(now);
        case TaskFilter.done:
          return isDone;
      }
    }).toList();

    // not-done first, then by due date, then newest
    list.sort((a, b) {
      final ad = a.data()['isDone'] == true;
      final bd = b.data()['isDone'] == true;
      if (ad != bd) return ad ? 1 : -1;
      final at = (a.data()['dueAt'] as Timestamp?)?.toDate();
      final bt = (b.data()['dueAt'] as Timestamp?)?.toDate();
      if (at != null && bt != null) return at.compareTo(bt);
      if (at != null) return -1;
      if (bt != null) return 1;
      final ac = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bc = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return bc.compareTo(ac);
    });
    return list;
  }

  // ------------------------------------------------------------------- UI

  Widget _header(List<TaskDoc> all) {
    final now = DateTime.now();
    var todayTotal = 0;
    var todayDone = 0;
    for (final d in all) {
      final due = (d.data()['dueAt'] as Timestamp?)?.toDate();
      if (due != null && _sameDay(due, now)) {
        todayTotal++;
        if (d.data()['isDone'] == true) todayDone++;
      }
    }

    final String mascot;
    final String line;
    if (todayTotal == 0) {
      mascot = '😊';
      line = 'No tasks due today';
    } else if (todayDone == todayTotal) {
      mascot = '🥳';
      line = 'All done for today!';
    } else if (todayDone * 2 >= todayTotal) {
      mascot = '😄';
      line = '${todayTotal - todayDone} left today, almost there!';
    } else if (todayDone > 0) {
      mascot = '🙂';
      line = '${todayTotal - todayDone} left today';
    } else {
      mascot = '😴';
      line = '$todayTotal tasks waiting today';
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? <String, dynamic>{};
        final xp = (data['xp'] as num?)?.toInt() ?? 0;
        final level = GameService.levelForXp(xp);
        final streak = GameService.effectiveStreak(data);

        return Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(mascot, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Level $level',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (xp % 100) / 100,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${xp % 100} / 100 XP',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                        Text('$streak',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('days', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: Text(line)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search tasks',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: _filterLabels.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _filter == e.key,
                    onSelected: (_) => setState(() => _filter = e.key),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _taskTile(TaskDoc doc) {
    final data = doc.data();
    final isDone = data['isDone'] == true;
    final due = (data['dueAt'] as Timestamp?)?.toDate();
    final overdue = due != null && !isDone && due.isBefore(DateTime.now());
    final description = (data['description'] ?? '') as String;
    final repeat = (data['repeat'] ?? 'none') as String;
    final reminder = (data['reminderMinutes'] as num?)?.toInt() ?? -1;

    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = dark ? const Color(0xff1F4E79) : const Color(0xff66B2FF);
    final onCard = dark ? Colors.white : Colors.black87;
    final overdueColor =
        dark ? const Color(0xffFFB4AB) : const Color(0xffB3261E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Opacity(
        opacity: isDone ? 0.6 : 1,
        child: Card(
          elevation: 6,
          color: cardColor,
          child: ListTile(
            onTap: () => _editTask(doc),
            textColor: onCard,
            iconColor: onCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_categoryIcon(data['category'] as String?)),
                const SizedBox(height: 6),
                CircleAvatar(
                  radius: 5,
                  backgroundColor: _priorityColor(data['priority'] as String?),
                ),
              ],
            ),
            title: Text(
              (data['title'] ?? '') as String,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty)
                  Text(description,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                if (due != null)
                  Text(
                    '${_formatDue(due)}${repeat != 'none' ? '  🔁' : ''}${reminder >= 0 ? '  🔔' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: overdue ? overdueColor : null,
                    ),
                  ),
                Text(
                  '${data['category'] ?? ''} · ${data['priority'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  activeColor: Colors.white,
                  checkColor: const Color.fromRGBO(33, 150, 243, 0.7),
                  value: isDone,
                  onChanged: (value) => _toggleDone(doc, value ?? false),
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Color.fromARGB(255, 159, 18, 18)),
                  onPressed: () => _deleteTask(doc),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0066cc),
        elevation: 13,
        title: const Text(
          'Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'New task',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addTask,
          ),
          IconButton(
            tooltip: 'Focus timer',
            icon: const Icon(Icons.timer, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FocusTimerScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tasks.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Could not load tasks. Check your internet and the Firestore rules.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data!.docs;
                final visible = _applyFilters(all);

                return Column(
                  children: [
                    _header(all),
                    _searchBar(),
                    _filterChips(),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(all.isEmpty
                                  ? 'No tasks yet. Tap + to add one.'
                                  : 'No tasks match.'),
                            )
                          : ListView.builder(
                              itemCount: visible.length,
                              itemBuilder: (context, index) =>
                                  _taskTile(visible[index]),
                            ),
                    ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 25,
                gravity: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
