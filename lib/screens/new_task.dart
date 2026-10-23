import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Used for both creating a task and editing one (pass [initial] to edit).
/// Returns a Map with the task fields when the user taps the button.
class NewTask extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const NewTask({super.key, this.initial});

  @override
  State<NewTask> createState() => _NewTaskState();
}

class _NewTaskState extends State<NewTask> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  static const List<String> _categories = ['Study', 'Work', 'Sport', 'Personal'];
  static const List<String> _priorities = ['Low', 'Medium', 'High'];
  // minutes before the due time (-1 = no reminder)
  static const Map<int, String> _reminderOptions = {
    -1: 'None',
    0: 'At due time',
    10: '10 min before',
    60: '1 hour before',
    1440: '1 day before',
  };
  static const Map<String, String> _repeatOptions = {
    'none': 'Never',
    'daily': 'Daily',
    'weekly': 'Weekly',
  };

  String _category = 'Personal';
  String _priority = 'Medium';
  String _repeat = 'none';
  int _reminder = 10;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  static const _blue = Color.fromRGBO(33, 150, 243, 1);

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _titleController =
        TextEditingController(text: (i?['title'] ?? '') as String);
    _descController =
        TextEditingController(text: (i?['description'] ?? '') as String);
    if (i != null) {
      _category = (i['category'] ?? 'Personal') as String;
      _priority = (i['priority'] ?? 'Medium') as String;
      _repeat = (i['repeat'] ?? 'none') as String;
      _reminder = (i['reminderMinutes'] as num?)?.toInt() ?? 10;
      final ts = i['dueAt'];
      if (ts is Timestamp) {
        final d = ts.toDate();
        _dueDate = DateTime(d.year, d.month, d.day);
        _dueTime = TimeOfDay(hour: d.hour, minute: d.minute);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // when editing an old task the saved date can be in the past
    final first =
        (_dueDate != null && _dueDate!.isBefore(today)) ? _dueDate! : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _message('Please enter a title');
      return;
    }
    if (_repeat != 'none' && _dueDate == null) {
      _message('Pick a due date for a repeating task');
      return;
    }

    DateTime? dueAt;
    if (_dueDate != null) {
      final t = _dueTime ?? const TimeOfDay(hour: 9, minute: 0);
      dueAt = DateTime(
          _dueDate!.year, _dueDate!.month, _dueDate!.day, t.hour, t.minute);
    }

    Navigator.pop(context, {
      'title': title,
      'description': _descController.text.trim(),
      'category': _category,
      'priority': _priority,
      'dueAt': dueAt,
      'repeat': _repeat,
      'reminderMinutes': dueAt == null ? -1 : _reminder,
    });
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final hasDate = _dueDate != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0066cc),
        foregroundColor: Colors.white,
        elevation: 13,
        title: Text(_editing ? 'Edit Task' : 'New Task',
            style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Title'),
                TextFormField(
                  controller: _titleController,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                _label('Description'),
                TextFormField(
                  controller: _descController,
                  minLines: 4,
                  maxLines: null,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                _label('Category'),
                Wrap(
                  spacing: 8,
                  children: _categories
                      .map((c) => ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                _label('Priority'),
                Wrap(
                  spacing: 8,
                  children: _priorities.map((p) {
                    final selected = _priority == p;
                    return ChoiceChip(
                      label: Text(p,
                          style:
                              TextStyle(color: selected ? Colors.white : null)),
                      selected: selected,
                      selectedColor: _priorityColor(p),
                      checkmarkColor: Colors.white,
                      onSelected: (_) => setState(() => _priority = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _label('Due date & time'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_dueDate == null
                            ? 'Pick date'
                            : '${_dueDate!.year}-${_two(_dueDate!.month)}-${_two(_dueDate!.day)}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: hasDate ? _pickTime : null,
                        icon: const Icon(Icons.access_time),
                        label: Text(_dueTime == null
                            ? 'Pick time'
                            : _dueTime!.format(context)),
                      ),
                    ),
                  ],
                ),
                if (hasDate)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _dueDate = null;
                        _dueTime = null;
                        _repeat = 'none';
                      }),
                      child: const Text('Remove due date'),
                    ),
                  ),
                const SizedBox(height: 16),
                _label('Reminder'),
                Wrap(
                  spacing: 8,
                  children: _reminderOptions.entries
                      .map((e) => ChoiceChip(
                            label: Text(e.value),
                            selected: _reminder == e.key,
                            onSelected: hasDate
                                ? (_) => setState(() => _reminder = e.key)
                                : null,
                          ))
                      .toList(),
                ),
                if (!hasDate)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Pick a due date to enable reminders',
                        style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(height: 24),
                _label('Repeat'),
                Wrap(
                  spacing: 8,
                  children: _repeatOptions.entries
                      .map((e) => ChoiceChip(
                            label: Text(e.value),
                            selected: _repeat == e.key,
                            onSelected: hasDate
                                ? (_) => setState(() => _repeat = e.key)
                                : null,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_editing ? 'Save' : 'Create',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
