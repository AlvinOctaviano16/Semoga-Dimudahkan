import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/models/user_model.dart';
import '../../../projects/providers/member_provider.dart'; 
import '../../domain/task_model.dart';
import '../../domain/task_provider.dart';
import '../../domain/task_status.dart';
import '../../domain/task_priority.dart';
// Import Repository agar bisa panggil fungsi notif
import '../../data/task_repository.dart'; 

class CreateTaskScreen extends ConsumerStatefulWidget {
  final String projectId;
  final TaskModel? taskToEdit;

  const CreateTaskScreen({
    super.key,
    required this.projectId,
    this.taskToEdit,
  });

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  String? _selectedAssigneeId;
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController = TextEditingController(text: widget.taskToEdit!.title);
      _descController = TextEditingController(text: widget.taskToEdit!.description);
      _selectedDate = widget.taskToEdit!.dueDate;
      _selectedAssigneeId = widget.taskToEdit!.assignedToId;
      _selectedPriority = widget.taskToEdit!.priority; 
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day + 1, 9, 0);
      _selectedAssigneeId = null; 
      _selectedPriority = TaskPriority.medium;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), 
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: ThemeData.light(), child: child!),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null) return;
    setState(() {
      _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    });
  }

  void _submitTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    if (_selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please assign to a member')));
      return;
    }

    final taskData = TaskModel(
      id: widget.taskToEdit?.id ?? const Uuid().v4(),
      projectId: widget.projectId,
      title: _titleController.text,
      description: _descController.text,
      status: widget.taskToEdit?.status ?? TaskStatus.todo,
      priority: _selectedPriority, 
      assignedToId: _selectedAssigneeId!, 
      proofUrl: widget.taskToEdit?.proofUrl,
      submissionComment: widget.taskToEdit?.submissionComment,
      completedAt: widget.taskToEdit?.completedAt,
      dueDate: _selectedDate,
      createAt: widget.taskToEdit?.createAt ?? DateTime.now(),
    );

    if (widget.taskToEdit != null) {
      // MODE EDIT
      ref.read(createTaskNotifierProvider.notifier).editTask(task: taskData);
    } else {
      // MODE CREATE
      ref.read(createTaskNotifierProvider.notifier).submitTask(task: taskData);
      
      // 👇 TRIGGER NOTIFIKASI KE ASSIGNEE
      // Kita panggil manual via Repository
      // Gunakan Future.delayed agar tidak menghambat UI pop
      Future.delayed(Duration.zero, () {
        ref.read(taskRepositoryProvider).notifyAssignee(
          _selectedAssigneeId!, 
          _titleController.text, 
          "SyncTask Project" 
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(createTaskNotifierProvider, (previous, next) {
      next.when(
        data: (_) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!'))); },
        error: (e, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))),
        loading: () {},
      );
    });

    final isLoading = ref.watch(createTaskNotifierProvider).isLoading;
    final isEditMode = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Task' : 'Add Task', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('What needs to be done?'),
                    TextField(controller: _titleController, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                      decoration: _inputDeco('Example: Fix Bug')),
                    const SizedBox(height: 20),
                    _buildLabel('Description'),
                    TextField(controller: _descController, 
                      maxLines: 3, 
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: _inputDeco('Details...')),
                    const SizedBox(height: 20),
                    _buildLabel('Priority'),
                    _buildPrioritySelector(),
                    const SizedBox(height: 20),
                    _buildLabel('Deadline'),
                    _buildDatePickerCard(),
                    const SizedBox(height: 20),
                    
                    _buildLabel('Assigned To'),
                    _buildRealMemberDropdown(), 
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitTask,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isEditMode ? "Save" : "Create Task", style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealMemberDropdown() {
    final membersAsync = ref.watch(projectMembersProvider(widget.projectId));

    return membersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => Text('Error loading members: $err', style: const TextStyle(color: Colors.red)),
      data: (members) {
        if (members.isEmpty) return const Text("No members found inside this project.");

        if (_selectedAssigneeId != null && !members.any((m) => m.uid == _selectedAssigneeId)) {
          _selectedAssigneeId = null; 
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAssigneeId,
              hint: const Text("Select Member"),
              isExpanded: true,
              items: members.map((user) {
                return DropdownMenuItem(
                  value: user.uid,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12, 
                        backgroundColor: AppColors.primary,
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Text(user.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAssigneeId = val),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));
  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
  
   Widget _buildPrioritySelector() {
    return Row(children: TaskPriority.values.map((p) => Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedPriority = p),
      child: Container(
        margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _selectedPriority == p ? AppColors.primary.withOpacity(0.1) : Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: _selectedPriority == p ? AppColors.primary : Colors.transparent)),
        child: Center(child: Text(p.displayValue, style: TextStyle(color: _selectedPriority == p ? AppColors.primary : Colors.grey))),
      ),
    ))).toList());
  }

  Widget _buildDatePickerCard() {
    return InkWell(
      onTap: _pickDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.calendar_today, color: AppColors.primary), const SizedBox(width: 10), Text(DateFormat('dd MMM yyyy, HH:mm').format(_selectedDate))]),
      ),
    );
  }
}