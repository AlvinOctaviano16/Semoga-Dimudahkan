import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import '../providers/member_provider.dart'; 
import 'create_project_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../task/presentation/screens/task_list_screen.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  Future<void> _removeMember(BuildContext context, WidgetRef ref, String memberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Member?"),
        content: Text("Are you sure you want to remove $memberName from this project?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Remove", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(projectRepositoryProvider).removeMember(
          projectId: project.id, 
          memberId: memberId
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$memberName removed successfully")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?', style: TextStyle(color: Colors.red)),
        content: const Text('This action cannot be undone. All tasks will be deleted too.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(projectRepositoryProvider).deleteProject(project.id);
      if (context.mounted) {
        Navigator.pop(context); // Kembali ke Dashboard
        Navigator.pop(context); 
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(projectMembersProvider(project.id));
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isAdmin = currentUser != null && currentUser.uid == project.ownerId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Project Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatScreen(
                  projectId: project.id,
                  projectName: project.name,
                ),
              ));
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CreateProjectScreen(projectToEdit: project)
                ));
              },
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProject(context, ref),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(project.description, style: const TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
            
            const SizedBox(height: 30),

            // 👇 REVISI: TOMBOL MENUJU TASK LIST
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TaskListScreen(project: project) 
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text(
                  "View Tasks & Board", 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            _buildSectionTitle("Invite Code"),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: project.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied!")));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(project.inviteCode, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const Icon(Icons.copy, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            _buildSectionTitle("Team Members"),
            
            membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text("Error: $err"),
              data: (members) {
                if (members.isEmpty) return const Text("No members yet.");
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final user = members[index];
                    final isMe = user.uid == currentUser?.uid;
                    final isOwner = user.uid == project.ownerId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isOwner ? Colors.orange : AppColors.primary,
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Row(
                        children: [
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (isMe) const Text(" (You)", style: TextStyle(color: Colors.grey)),
                          if (isOwner) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, size: 14, color: Colors.orange),
                          ]
                        ],
                      ),
                      subtitle: Text(user.email),
                      trailing: (isAdmin && !isMe) 
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeMember(context, ref, user.uid, user.name),
                          ) 
                        : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.0)),
    );
  }
}