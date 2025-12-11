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
      // 👇 Dark Theme untuk Date Picker
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surface)), child: child!),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surface)), child: child!),
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
      ref.read(createTaskNotifierProvider.notifier).editTask(task: taskData);
    } else {
      ref.read(createTaskNotifierProvider.notifier).submitTask(task: taskData);
      
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
      backgroundColor: AppColors.background, // Background Gelap
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Task' : 'Add Task', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white), // Teks Putih
                      decoration: _inputDeco('Example: Fix Bug')),
                    const SizedBox(height: 20),
                    _buildLabel('Description'),
                    TextField(controller: _descController, 
                      maxLines: 3, 
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isEditMode ? "Save" : "Create Task", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
        if (members.isEmpty) return const Text("No members found inside this project.", style: TextStyle(color: Colors.grey));

        if (_selectedAssigneeId != null && !members.any((m) => m.uid == _selectedAssigneeId)) {
          _selectedAssigneeId = null; 
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)), // Container Gelap
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAssigneeId,
              hint: const Text("Select Member", style: TextStyle(color: Colors.grey)),
              isExpanded: true,
              dropdownColor: AppColors.surface, // Menu Dropdown Gelap
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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
                      Text(user.name, style: const TextStyle(color: Colors.white)), // Teks Putih
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

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400])));
  
  // Update Input Deco agar gelap
  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, 
    hintStyle: TextStyle(color: Colors.grey[600]),
    filled: true, 
    fillColor: AppColors.surface, 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );
  
   Widget _buildPrioritySelector() {
    return Row(children: TaskPriority.values.map((p) => Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedPriority = p),
      child: Container(
        margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedPriority == p ? AppColors.primary.withOpacity(0.2) : AppColors.surface, 
          borderRadius: BorderRadius.circular(8), 
          border: Border.all(color: _selectedPriority == p ? AppColors.primary : Colors.transparent)
        ),
        child: Center(child: Text(p.displayValue, style: TextStyle(color: _selectedPriority == p ? AppColors.primary : Colors.grey[400]))),
      ),
    ))).toList());
  }

  Widget _buildDatePickerCard() {
    return InkWell(
      onTap: _pickDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.calendar_today, color: AppColors.primary), const SizedBox(width: 10), Text(DateFormat('dd MMM yyyy, HH:mm').format(_selectedDate), style: const TextStyle(color: Colors.white))]),
      ),
    );
  }
}