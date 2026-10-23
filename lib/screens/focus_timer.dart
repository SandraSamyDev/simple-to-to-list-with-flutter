import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/services/game_service.dart';

class _Mode {
  final String label;
  final int minutes;
  final bool isBreak;
  const _Mode(this.label, this.minutes, this.isBreak);
}

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  static const List<_Mode> _modes = [
    _Mode('Focus 15', 15, false),
    _Mode('Focus 25', 25, false),
    _Mode('Focus 45', 45, false),
    _Mode('Break 5', 5, true),
  ];

  int _selected = 1;
  late int _remaining = _modes[_selected].minutes * 60;
  Timer? _timer;

  bool get _running => _timer != null;
  _Mode get _mode => _modes[_selected];
  int get _total => _mode.minutes * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    final endAt = DateTime.now().add(Duration(seconds: _remaining));
    // the end time is fixed, so the timer stays correct even if the app
    // was in the background for a while
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final ms = endAt.difference(DateTime.now()).inMilliseconds;
      final left = (ms / 1000).ceil();
      if (left <= 0) {
        _finish();
      } else if (mounted) {
        setState(() => _remaining = left);
      }
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() => _remaining = _total);
  }

  void _select(int index) {
    if (_running) return;
    setState(() {
      _selected = index;
      _remaining = _total;
    });
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

  Future<void> _finish() async {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    setState(() => _remaining = 0);

    if (_mode.isBreak) {
      await _info('Break is over', 'Ready for the next focus session?');
    } else {
      try {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final res = await GameService.focusDone(uid);
        if (!mounted) return;
        await _info('Great focus! 🎯', '+${res.xpGained} XP');
        for (final id in res.newAchievements) {
          final a = GameService.byId(id);
          if (a == null || !mounted) continue;
          await _info('Achievement unlocked ${a.emoji}', a.title);
        }
      } catch (_) {
        if (!mounted) return;
        await _info('Session finished', 'Could not save your points.');
      }
    }

    if (mounted) setState(() => _remaining = _total);
  }

  String _clock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? 0.0 : 1 - (_remaining / _total);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0066cc),
        foregroundColor: Colors.white,
        elevation: 13,
        title: const Text('Focus timer', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < _modes.length; i++)
                      ChoiceChip(
                        label: Text(_modes[i].label),
                        selected: _selected == i,
                        onSelected: _running ? null : (_) => _select(i),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _clock(_remaining),
                            style: const TextStyle(
                                fontSize: 54, fontWeight: FontWeight.bold),
                          ),
                          Text(_mode.isBreak ? 'Take a break ☕' : 'Stay focused 🎯'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _running ? _pause : _start,
                      icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                      label: Text(_running ? 'Pause' : 'Start'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Finish a focus session to earn +15 XP',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
