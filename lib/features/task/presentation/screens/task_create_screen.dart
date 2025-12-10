import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import 'package:sync_task_app/core/constants/app_colors.dart';
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:sync_task_app/features/task/domain/task_provider.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';
import 'package:sync_task_app/features/task/domain/task_priority.dart';
import 'package:uuid/uuid.dart';

class TeamMember {
  final String id;
  final String name;
  TeamMember(this.id, this.name);
}

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
  
  // State untuk Priority
  TaskPriority _selectedPriority = TaskPriority.medium;

  final List<TeamMember> _teamMembers = [
    TeamMember('user-alvin', 'Alvin (Saya)'),
    TeamMember('user-farid', 'Farid'),
    TeamMember('user-budi', 'Budi'),
  ];

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
      _selectedAssigneeId = _teamMembers.first.id;
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submitTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul wajib diisi')));
      return;
    }
    if (_selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih anggota tim')));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(createTaskNotifierProvider, (previous, next) {
      next.when(
        data: (_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil disimpan!')));
        },
        error: (e, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))),
        loading: () {},
      );
    });

    final isLoading = ref.watch(createTaskNotifierProvider).isLoading;
    final isEditMode = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Task' : 'Add Task',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                    // 1. INPUT JUDUL (Besar & Bersih)
                    _buildLabel('What needs to be done?'),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: _modernInputDecoration('Example : Redesign Homepage'),
                    ),
                    const SizedBox(height: 24),

                    // 2. INPUT DESKRIPSI
                    _buildLabel('Detail / Description'),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: _modernInputDecoration('Add detail notes...'),
                    ),
                    const SizedBox(height: 24),

                    // 3. PRIORITY SELECTOR (CHIPS)
                    _buildLabel('Priority'),
                    _buildPrioritySelector(),
                    const SizedBox(height: 24),

                    // 4. DATE PICKER (CARD STYLE)
                    _buildLabel('Deadline'),
                    _buildDatePickerCard(),
                    const SizedBox(height: 24),

                    // 5. ASSIGNEE DROPDOWN
                    _buildLabel('Assigned To'),
                    _buildAssigneeDropdown(),
                    
                    const SizedBox(height: 40), // Ruang bawah
                  ],
                ),
              ),
            ),
            
            // 6. TOMBOL SIMPAN (FIXED DI BAWAH)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ]
              ),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditMode ? "Save Changes" : "Create Task",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.grey[50], // Background abu-abu sangat muda
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, // Hilangkan border garis
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }

  // Widget Pemilih Prioritas (Horizontal Chips)
  Widget _buildPrioritySelector() {
    return Row(
      children: TaskPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        Color color;
        switch (priority) {
          case TaskPriority.high: color = AppColors.highPriority; break;
          case TaskPriority.medium: color = AppColors.mediumPriority; break;
          case TaskPriority.low: color = AppColors.lowPriority; break;
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = priority),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.flag_rounded, 
                    size: 20, 
                    color: isSelected ? color : Colors.grey[400]
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priority.displayValue,
                    style: TextStyle(
                      color: isSelected ? color : Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget Kartu Tanggal
  Widget _buildDatePickerCard() {
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final timeStr = DateFormat('HH:mm').format(_selectedDate);

    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText),
                ),
                Text(
                  "Pukul $timeStr",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Widget Dropdown Assignee
  Widget _buildAssigneeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent), // Transparan agar senada
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAssigneeId,
          hint: const Text("Pilih Anggota Tim"),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: _teamMembers.map((member) {
            return DropdownMenuItem(
              value: member.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14, 
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(member.name[0], style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Text(member.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAssigneeId = value;
            });
          },
        ),
      ),
    );
  }
}