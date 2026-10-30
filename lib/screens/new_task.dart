import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewTask extends StatefulWidget {
  const NewTask({super.key});

  @override
  State<NewTask> createState() => _NewTaskState();
}

class _NewTaskState extends State<NewTask> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String selectedCategory = 'Study 📚';
  String selectedPriority = 'Medium ⚡';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isSaving = false;

  final List<String> categories = [
    'Study 📚',
    'Work 💻',
    'Personal 💖',
    'Self-Care 💅',
    'Fitness 🏋️‍♀️',
    'Shopping 🛍️',
    'Events 🎈',
  ];
  final List<String> priorities = ['High 🔥', 'Medium ⚡', 'Low 🍃'];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFFF758F),
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF758F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _saveTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the task title at least!")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // حفظ التاسك في الفايربيز
        await FirebaseFirestore.instance.collection('tasks').add({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'category': selectedCategory,
          'priority': selectedPriority,
          'date': selectedDate != null
              ? "${selectedDate!.day}/${selectedDate!.month}"
              : '',
          'time': selectedTime != null ? selectedTime!.format(context) : '',
          'userId': user.uid,
          'createdAt': Timestamp.now(),
          'isDone': false,
        });
      }

      // الرجوع التلقائي الفوري والمباشر
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF758F),
        elevation: 0,
        title: const Text(
          "✨ New Task",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Task Title",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4F4F),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Enter task title...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF758F),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Description (Optional)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4F4F),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter task details...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF758F),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Category",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4F4F),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 20),

              const Text(
                "Priority",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4F4F),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: priorities.map((prio) {
                  return DropdownMenuItem(value: prio, child: Text(prio));
                }).toList(),
                onChanged: (val) => setState(() => selectedPriority = val!),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        selectedDate == null
                            ? "Pick Date"
                            : "${selectedDate!.day}/${selectedDate!.month}",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF758F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        selectedTime == null
                            ? "Pick Time"
                            : selectedTime!.format(context),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF758F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF758F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 5,
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Save Task 💖",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
