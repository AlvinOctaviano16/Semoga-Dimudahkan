import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/models/user_model.dart'; 
import '../../../auth/screens/profile_screen.dart';
import '../../../projects/models/project_model.dart';
import '../../../projects/providers/member_provider.dart'; 
import '../../data/task_repository.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';
import '../../domain/task_provider.dart';
import '../widgets/task_priority_chip.dart';

class TaskListScreen extends ConsumerWidget {
  final ProjectModel project;

  const TaskListScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListStreamProvider(project.id));
    final membersAsync = ref.watch(projectMembersProvider(project.id));
    
    final currentFilter = ref.watch(filterTypeProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isAdmin = currentUser != null && currentUser.uid == project.ownerId;

    return Scaffold(
      // 👇 UBAH: Background Gelap
      backgroundColor: AppColors.background, 
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(context),
            _buildFilterTabs(ref, currentFilter),
            const SizedBox(height: 10),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
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
                          Icon(Icons.assignment_outlined, size: 60, color: AppColors.surface.withOpacity(0.5)),
                          const SizedBox(height: 10),
                          // 👇 UBAH: Teks lebih terang
                          Text('No tasks found ($currentFilter)', style: const TextStyle(color: Colors.grey)), 
                        ],
                      ),
                    );
                  }

                  final List<UserModel> members = membersAsync.value ?? [];

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
                          color: Colors.red[900], // Merah agak gelap biar gak nyolok mata
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          ref.read(taskRepositoryProvider).deleteTask(task.id);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${task.title} deleted')));
                        },
                        child: _buildTaskItem(context, task, ref, members),
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
      floatingActionButton: isAdmin 
        ? FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTaskScreen(projectId: project.id)));
            },
            backgroundColor: AppColors.primary,
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : null,
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final String todayDate = DateFormat('EEEE, d MMM').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. TOMBOL BACK (Warna Putih)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Project',
          ),
          
          const SizedBox(width: 4),

          // 2. JUDUL PROJECT (Warna Putih)
          Expanded( 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${project.name} Tasks', 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white, // 👇 UBAH JADI PUTIH
                    fontWeight: FontWeight.w800,
                    fontSize: 22, 
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // 👇 UBAH: Grey yang lebih terang
                Text(todayDate, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500)), 
              ],
            ),
          ),
          
          const SizedBox(width: 10), 
          
          // 3. PROFILE ICON
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                color: AppColors.surface, // 👇 Background Surface
                shape: BoxShape.circle, 
                border: Border.all(color: AppColors.primary, width: 2) // Border Biru
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
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
      onTap: () => ref.read(filterTypeProvider.notifier).setFilter(text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // 👇 UBAH: Logika Warna Filter (Aktif=Biru, Mati=Surface)
          color: isActive ? AppColors.primary : AppColors.surface, 
          borderRadius: BorderRadius.circular(30)
        ),
        child: Text(
          text, 
          // 👇 UBAH: Teks selalu putih/terang agar kontras
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[400], 
            fontWeight: FontWeight.bold, 
            fontSize: 14
          )
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task, WidgetRef ref, List<UserModel> members) {
    final bool isCompleted = task.status == TaskStatus.done;
    final normalDateString = DateFormat('d MMM').format(task.dueDate);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAssignee = currentUser != null && currentUser.uid == task.assignedToId;

    final assigneeUser = members.firstWhere(
      (user) => user.uid == task.assignedToId,
      orElse: () => UserModel(uid: '', email: '', name: 'Unknown'), 
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface, // 👇 UBAH: Background Kartu jadi Gelap (Surface)
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2)) // Shadow lebih gelap
        ]
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, projectOwnerId: project.ownerId)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: isAssignee 
                  ? () { ref.read(taskRepositoryProvider).updateTask(task.id, isCompleted ? TaskStatus.todo : TaskStatus.done); }
                  : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only the assignee can complete this task!"))); },
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: isCompleted ? Colors.green : Colors.transparent, 
                    border: Border.all(
                      // 👇 Border warna putih/abu jika belum selesai
                      color: isCompleted ? Colors.green : (isAssignee ? Colors.grey[400]! : Colors.grey[800]!)
                    )
                  ),
                  child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 12),
              
              // Info Task
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        decoration: isCompleted ? TextDecoration.lineThrough : null, 
                        decorationColor: Colors.grey,
                        // 👇 UBAH: Warna Judul Putih (atau dimmed jika selesai)
                        color: isCompleted ? Colors.white38 : Colors.white 
                      )
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(normalDateString, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        const SizedBox(width: 12), 
                        
                        // Assignee Pill
                        Container(
                          padding: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black26, // 👇 Background Pill Assignee lebih gelap
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.primary.withOpacity(0.7),
                                child: Text(assigneeUser.name.isNotEmpty ? assigneeUser.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 8, color: Colors.white)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                assigneeUser.name, 
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70), // Teks Assignee Putih
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TaskPriorityChip(priority: task.priority),
            ],
          ),
        ),
      ),
    );
  }
}