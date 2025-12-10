import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import 'package:sync_task_app/core/constants/app_colors.dart';
import 'package:sync_task_app/features/task/data/task_repository.dart'; 
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:sync_task_app/features/task/domain/task_provider.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';
import 'package:sync_task_app/features/task/domain/task_priority_chip.dart'; 
import 'package:sync_task_app/features/task/presentation/screens/task_create_screen.dart';
import 'package:sync_task_app/features/task/presentation/screens/task_detail_screen.dart';

class TaskListScreen extends ConsumerWidget {
  final String projectId;
  const TaskListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListStreamProvider(projectId));
    final currentFilter = ref.watch(filterTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(),
            _buildFilterTabs(ref, currentFilter),
            const SizedBox(height: 10),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                error: (err, stack) =>
                    Center(child: Text('Error loading tasks : $err')),
                data: (tasks) {
                  final filteredTasks = tasks.where((task) {
                    if (currentFilter == 'All') return true;
                    if (currentFilter == 'Complete') return task.status == TaskStatus.done;
                    if (currentFilter == 'Pending') return task.status != TaskStatus.done;
                    return true;
                  }).toList();

                  if (filteredTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          // Bahasa Inggris
                          Text('No tasks found ($currentFilter)', 
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 0, bottom: 80),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Dismissible(
                        key: Key(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.red[50],
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                        onDismissed: (direction) {
                          ref.read(taskRepositoryProvider).deleteTask(task.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            // Bahasa Inggris
                            SnackBar(content: Text('${task.title} deleted')),
                          );
                        },
                        child: _buildTaskItem(context, task, ref),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreateTaskScreen(projectId: projectId)),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        // Bahasa Inggris
        label: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildModernHeader() {
    // Format tanggal Inggris
    final String todayDate = DateFormat('EEEE, d MMM').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Tasks',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(todayDate, style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 28), color: AppColors.primaryText, onPressed: () {}),
              const SizedBox(width: 8),
              Container(
                width: 45, height: 45,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: const Icon(Icons.person, color: AppColors.primaryBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(WidgetRef ref, String currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _filterButton(ref, 'All', currentFilter),
          const SizedBox(width: 12),
          _filterButton(ref, 'Complete', currentFilter),
          const SizedBox(width: 12),
          _filterButton(ref, 'Pending', currentFilter),
        ],
      ),
    );
  }

  Widget _filterButton(WidgetRef ref, String text, String currentFilter) {
    final isActive = text == currentFilter;
    return GestureDetector(
      onTap: () {
        ref.read(filterTypeProvider.notifier).setFilter(text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryText : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive ? [BoxShadow(color: AppColors.primaryText.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task, WidgetRef ref) {
    final bool isCompleted = task.status == TaskStatus.done;
    final DateTime now = DateTime.now();

    // 1. Overdue: Belum selesai DAN waktu sekarang > deadline
    final bool isOverdue = !isCompleted && now.isAfter(task.dueDate);

    // 2. Late: Sudah selesai DAN waktu selesai > deadline
    // Pastikan completedAt tidak null
    final bool isLate = isCompleted && 
                        task.completedAt != null && 
                        task.completedAt!.isAfter(task.dueDate);

    final normalDateString = DateFormat('d MMM, HH:mm').format(task.dueDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  final newStatus = isCompleted ? TaskStatus.todo : TaskStatus.done;
                  // Update Status + completedAt (via logika baru di Repository)
                  ref.read(taskRepositoryProvider).updateTask(task.id, newStatus);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.completedGreen : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? AppColors.completedGreen : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isCompleted 
                      ? const Icon(Icons.check, size: 16, color: Colors.white) 
                      : null,
                ),
              ),
              
              const SizedBox(width: 12),

              // Detail Tugas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: isCompleted ? Colors.grey : AppColors.primaryText,
                        fontSize: 16,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[500], 
                          fontSize: 13,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),

                    // --- LOGIKA TAMPILAN STATUS WAKTU (ENGLISH) ---
                    if (isOverdue) ...[
                      // Tampilan Overdue (Merah)
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          const Text(
                            "Overdue", // Bahasa Inggris
                            style: TextStyle(
                              color: Colors.red, 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(
                            " • $normalDateString",
                            style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      )
                    ] else if (isLate) ...[
                      // Tampilan Late (Oranye)
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          const Text(
                            "Done Late", // Bahasa Inggris
                            style: TextStyle(
                              color: Colors.orange, 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text(
                            " • $normalDateString",
                            style: TextStyle(color: Colors.orange.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      )
                    ] else ...[
                      // Tampilan Normal
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            normalDateString,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      )
                    ],
                    // ---------------------------------------------
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Priority Chip
              TaskPriorityChip(priority: task.priority),
            ],
          ),
        ),
      ),
    );
  }
}