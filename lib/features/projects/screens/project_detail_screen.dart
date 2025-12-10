import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Untuk fitur copy text

import '../models/project_model.dart';
import '../providers/project_provider.dart';
import 'create_project_screen.dart'; 

class ProjectDetailScreen extends ConsumerWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  // Fungsi Menghapus Proyek
  Future<void> _deleteProject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Proyek?'),
        content: const Text('Proyek ini akan dihapus permanen. Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(project.id);
        if (context.mounted) {
          Navigator.pop(context); // Kembali ke Dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proyek berhasil dihapus')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Proyek"),
        actions: [
          // TOMBOL EDIT BARU
  IconButton(
    icon: const Icon(Icons.edit, color: Colors.blue),
    onPressed: () {
      // Navigasi ke CreateProjectScreen TAPI bawa data 'project'
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateProjectScreen(projectToEdit: project),
        ),
      );
    },
  ),
          // Tombol Delete (Bagian dari CRUD Project)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteProject(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Judul & Deskripsi
            _buildSectionTitle("Nama Proyek"),
            Text(project.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildSectionTitle("Deskripsi"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                project.description,
                style: TextStyle(fontSize: 16, color: Colors.blue.shade900),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Kode Undangan (Penting untuk Project Management)
            _buildSectionTitle("Kode Undangan"),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: project.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kode disalin ke clipboard!")),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      project.inviteCode,
                      style: const TextStyle(
                        fontSize: 24, 
                        letterSpacing: 4, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    const Icon(Icons.copy, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Bagikan kode ini ke teman untuk bergabung.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Info Member (Sederhana)
            _buildSectionTitle("Anggota Tim"),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text("Project Owner"),
              subtitle: Text(project.ownerId), // Nanti bisa diganti nama asli jika ada User Model
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey.shade600
        ),
      ),
    );
  }
}