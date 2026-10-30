import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'new_task.dart';
import 'login.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  String searchQuery = '';
  String selectedFilter = 'All';

  final List<String> allCategories = [
    'All',
    'Study 📚',
    'Work 💻',
    'Personal 💖',
    'Self-Care 💅',
    'Fitness 🏋️‍♀️',
    'Shopping 🛍️',
    'Events 🎈',
  ];

  void _showEditBottomSheet(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    TextEditingController editTitleController = TextEditingController(
      text: data['title'],
    );
    TextEditingController editDescController = TextEditingController(
      text: data['description'],
    );
    String editCategory = data['category'] ?? 'Personal 💖';
    String editPriority = data['priority'] ?? 'Medium ⚡';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.pink[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Edit Task ✏️",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4F4F),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: editTitleController,
                        decoration: InputDecoration(
                          labelText: "Title",
                          filled: true,
                          fillColor: const Color(0xFFFFF0F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: editDescController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description",
                          filled: true,
                          fillColor: const Color(0xFFFFF0F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: allCategories.contains(editCategory)
                            ? editCategory
                            : 'Personal 💖',
                        decoration: InputDecoration(
                          labelText: "Category",
                          filled: true,
                          fillColor: const Color(0xFFFFF0F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: allCategories.where((c) => c != 'All').map((
                          cat,
                        ) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => editCategory = val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: editPriority,
                        decoration: InputDecoration(
                          labelText: "Priority",
                          filled: true,
                          fillColor: const Color(0xFFFFF0F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['High 🔥', 'Medium ⚡', 'Low 🍃'].map((prio) {
                          return DropdownMenuItem(
                            value: prio,
                            child: Text(prio),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => editPriority = val!),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF758F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(docId)
                              .update({
                                'title': editTitleController.text.trim(),
                                'description': editDescController.text.trim(),
                                'category': editCategory,
                                'priority': editPriority,
                              });
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          "Update Task ✨",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF758F),
        elevation: 0,
        title: const Text(
          "✨ My Tasks",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) =>
                      setState(() => searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search tasks...",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFFF758F),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: allCategories.map((cat) {
                      bool isSelected = selectedFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFF758F),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFFF758F),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) =>
                                setState(() => selectedFilter = cat),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF758F)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tasks yet! Add a new one 💖",
                      style: TextStyle(color: Color(0xFF6B4F4F), fontSize: 16),
                    ),
                  );
                }

                var tasks = snapshot.data!.docs;

                var filteredTasks = tasks.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = data['title']?.toLowerCase() ?? '';
                  String category = data['category'] ?? '';

                  bool matchesSearch = title.contains(searchQuery);
                  bool matchesCategory =
                      selectedFilter == 'All' || category == selectedFilter;

                  return matchesSearch && matchesCategory;
                }).toList();

                int completedCount = tasks
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['isDone'] ==
                          true,
                    )
                    .length;
                double progressRatio = tasks.isEmpty
                    ? 0
                    : completedCount / tasks.length;

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Daily Progress 🎀",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B4F4F),
                                ),
                              ),
                              Text(
                                "${(progressRatio * 100).toInt()}% Done",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF758F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              backgroundColor: const Color(0xFFFFF0F5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF758F),
                              ),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: filteredTasks.isEmpty
                          ? const Center(
                              child: Text(
                                "No matching tasks found!",
                                style: TextStyle(
                                  color: Color(0xFF6B4F4F),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                var taskDoc = filteredTasks[index];
                                var taskData =
                                    taskDoc.data() as Map<String, dynamic>;
                                String docId = taskDoc.id;

                                bool isDone = taskData['isDone'] ?? false;
                                String title = taskData['title'] ?? '';
                                String description =
                                    taskData['description'] ?? '';
                                String category = taskData['category'] ?? '';
                                String priority = taskData['priority'] ?? '';
                                String date = taskData['date'] ?? '';
                                String time = taskData['time'] ?? '';

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                      child: Checkbox(
                                        key: ValueKey(isDone),
                                        value: isDone,
                                        activeColor: const Color(0xFFFF758F),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          FirebaseFirestore.instance
                                              .collection('tasks')
                                              .doc(docId)
                                              .update({'isDone': val});
                                        },
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isDone
                                            ? Colors.grey
                                            : const Color(0xFF333333),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            description,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Chip(
                                              label: Text(
                                                category,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: const Color(
                                                0xFFFFB6C1,
                                              ),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            Chip(
                                              label: Text(
                                                priority,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: const Color(
                                                0xFFFF758F,
                                              ),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            if (date.isNotEmpty ||
                                                time.isNotEmpty)
                                              Chip(
                                                label: Text(
                                                  "$date $time",
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF6B4F4F),
                                                  ),
                                                ),
                                                backgroundColor: const Color(
                                                  0xFFFFF0F5,
                                                ),
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Color(0xFFFF758F),
                                          ),
                                          onPressed: () => _showEditBottomSheet(
                                            context,
                                            docId,
                                            taskData,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('tasks')
                                                .doc(docId)
                                                .delete();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF758F),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "New Task",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewTask()),
          );
        },
      ),
    );
  }
}
