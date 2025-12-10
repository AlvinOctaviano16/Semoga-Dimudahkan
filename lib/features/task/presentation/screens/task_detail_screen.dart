import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/storage_service.dart';
import '../../data/task_repository.dart';
import '../../domain/task_model.dart';
import '../../domain/task_status.dart'; 
import '../widgets/task_status_chip.dart';
import '../widgets/task_priority_chip.dart'; 
import 'task_create_screen.dart';
import 'dart:convert';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;
  final String projectOwnerId;

  const TaskDetailScreen({
    super.key, 
    required this.task,
    required this.projectOwnerId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isUploading = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _uploadProof() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo (Camera)'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 25, // Kompresi kualitas
      maxWidth: 800,   // Resize lebar maksimum
      );
    
    if (image != null) {
      if (!mounted) return;
      
      String? comment = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add a comment"),
            content: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Example: Done, but i think it can be improved",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _commentController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Sesuaikan warna
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Send", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (comment == null) return;

      setState(() => _isUploading = true);
      
      try {
        final file = File(image.path);
        // Upload gambar ke Storage
        final downloadUrl = await ref
            .read(storageRepositoryProvider)
            .uploadImageProof(file, widget.task.id);

        // Update Data Task di Firestore
        await ref.read(taskRepositoryProvider).submitTaskCompletion(
          taskId: widget.task.id,
          proofUrl: downloadUrl,
          comment: comment,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task successfully done!')),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // Logic Delete (Hanya Admin)
  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Task?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(taskRepositoryProvider).deleteTask(widget.task.id);
      if (mounted) Navigator.pop(context); // Kembali ke list
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format Waktu
    final dateFormatted = DateFormat('EEEE, d MMM yyyy • HH:mm').format(widget.task.dueDate);
    
    final completedFormatted = widget.task.completedAt != null
        ? DateFormat('d MMM yyyy, HH:mm').format(widget.task.completedAt!)
        : '-';

    // Define Roles (Siapa yang Login?)
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isAdmin = currentUser != null && currentUser.uid == widget.projectOwnerId;
    final bool isAssignee = currentUser != null && currentUser.uid == widget.task.assignedToId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Task Detail',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        actions: [
          // Tombol Edit: Hanya untuk Admin
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTaskScreen(
                      projectId: widget.task.projectId, 
                      taskToEdit: widget.task,
                    ),
                  ),
                );
              },
            ),
          // Tombol Delete: Hanya untuk Admin
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CHIPS HEADER (Priority & Status)
            Row(
              children: [
                TaskPriorityChip(priority: widget.task.priority),
                const SizedBox(width: 8),
                TaskStatusChip(status: widget.task.status),
              ],
            ),
            const SizedBox(height: 16),

            // 2. JUDUL TUGAS
            Text(
              widget.task.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // 3. DEADLINE
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                    Text(
                      dateFormatted,
                      style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            const Divider(color: AppColors.dividerColor, thickness: 1),
            const SizedBox(height: 20),

            // 4. DESKRIPSI
            _buildSectionLabel('Description'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.task.description.isEmpty 
                    ? 'No additional description.' 
                    : widget.task.description,
                style: const TextStyle(
                  color: AppColors.primaryText, 
                  fontSize: 15, 
                  height: 1.5
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 5. BUKTI PENGERJAAN (PROOF OF WORK)
            _buildSectionLabel('Proof of Work'),
            
            // --- LOGIC TAMPILAN (FIXED) ---
            
            // KONDISI A: Sudah Ada Bukti (Berarti Selesai)
            if (widget.task.proofUrl != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Task Completed on $completedFormatted',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.task.submissionComment != null && widget.task.submissionComment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '"${widget.task.submissionComment}"',
                          style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Gambar Bukti
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImageDisplay(widget.task.proofUrl!),
              ),
              
              // Tombol Revisi (Hanya Assignee yang bisa lihat)
              if (isAssignee) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _uploadProof,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Revision / re-upload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ] 
            
            // KONDISI B: Belum Ada Bukti (Belum Selesai)
            else ...[ 
              if (isAssignee) ...[
                // B1: Saya Assignee -> Tampilkan Kartu Upload
                GestureDetector(
                  onTap: _isUploading ? null : _uploadProof,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: _isUploading 
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                  ]
                                ),
                                child: const Icon(Icons.cloud_upload_rounded, size: 32, color: AppColors.primary), // Gunakan AppColors.primary atau primaryBlue
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Upload Proof of Work',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to take a photo from the gallery',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
              ] else ...[
                // B2: Saya Bukan Assignee (Admin/Member Lain) -> Tampilkan Pesan Tunggu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 40, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        isAdmin
                            ? "Waiting for assignee to complete this task."
                            : "This task is assigned to someone else.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper Widget
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Helper untuk menentukan cara menampilkan gambar
  Widget _buildImageDisplay(String imageString) {
    // 1. Jika URL Link (https://...)
    if (imageString.startsWith('http')) {
      return Image.network(
        imageString,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
            height: 220,
            color: Colors.grey[200],
            child: const Center(child: Text("Failed to load link"))),
      );
    } 
    
    // 2. Jika Base64 String (Kode panjang)
    try {
      // Kita perlu import 'dart:convert'; di paling atas file ini
      final decodedBytes = base64Decode(imageString);
      return Image.memory(
        decodedBytes,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
            height: 220,
            color: Colors.grey[200],
            child: const Center(child: Text("Failed to Load Base64"))),
      );
    } catch (e) {
      return Container(height: 220, color: Colors.grey[200], child: const Center(child: Text("Format Salah")));
    }
  }
}