import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/screens/profile_screen.dart';
import '../providers/project_provider.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart'; 
import '../../task/presentation/screens/task_list_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; // Butuh UID user
import '../repositories/project_repository.dart'; // Butuh akses fungsi join

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectListAsync = ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Projects", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Tombol Profile
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: projectListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (projects) {
          if (projects.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(project.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    project.description, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary)
                  ),
                  
                  // 👇 BAGIAN UTAMA: Navigasi ke Task List
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        // Update: kirim full project model
                        builder: (_) => TaskListScreen(project: project),
                      )
                    );
                  },
                  
                  // Tombol Info kecil untuk lihat Detail Project (Kode Undangan/Delete)
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                    onPressed: () {
                       Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(project: project),
                        )
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol Join Project
          FloatingActionButton.small(
            heroTag: "join_btn", // Wajib beda tag
            backgroundColor: AppColors.surface,
            onPressed: () => _showJoinDialog(context, ref),
            child: const Icon(Icons.link, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Tombol Create Project
          FloatingActionButton.extended(
            heroTag: "create_btn",
            backgroundColor: AppColors.primary,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("New Project", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: AppColors.surface.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            "No projects yet",
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
            ),
            child: const Text("Create First Project"),
          )
        ],
      ),
    );
  }

  // UI Dialog untuk input kode undangan
  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Join Project", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the invite code shared by your team lead.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ex: 829103",
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                // Panggil Logic Join
                await ref.read(projectRepositoryProvider).joinProject(
                  inviteCode: code, 
                  userId: user.uid
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx); // Tutup Dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Successfully joined!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx); // Tutup Dialog dulu biar enak
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            }, 
            child: const Text("Join", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }
}