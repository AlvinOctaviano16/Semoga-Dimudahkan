import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // [PENTING] Tambah import ini
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/screens/profile_screen.dart';
import '../providers/project_provider.dart';
import '../repositories/project_repository.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart'; 

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  
  @override
  void initState() {
    super.initState();
    _syncUserData();
  }

  // 👇 FUNGSI BARU: GABUNGAN SIMPAN TOKEN + UPDATE EMAIL
  Future<void> _syncUserData() async {
    // 1. Ambil user saat ini dari Auth (Login Session)
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // [PENTING] Paksa aplikasi tarik data terbaru dari server Firebase Auth
        // Ini yang memperbaiki masalah "email masih lama"
        await user.reload();
        user = FirebaseAuth.instance.currentUser; // Refresh variabel user
        
        if (user == null) return;

        print("🔍 Syncing User: ${user.email}");

        // 2. Siapkan Data yang mau di-update ke Database Firestore
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        final Map<String, dynamic> updates = {
          'lastActive': FieldValue.serverTimestamp(),
        };

        // 3. Masukkan Email Terbaru (dari Auth) ke Data Update
        if (user.email != null) {
          updates['email'] = user.email; 
        }

        // 4. Masukkan Token FCM (untuk Notifikasi)
        final token = await NotificationService().getToken();
        if (token != null) {
          updates['fcmToken'] = token;
        }

        // 5. Eksekusi Update ke Firestore (Merge agar data lain tidak hilang)
        await userDocRef.set(updates, SetOptions(merge: true));
        
        print("✅ Data User berhasil disinkronisasi (Email & Token)");
        
      } catch (e) {
        print("⚠️ Gagal sinkronisasi user: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectListAsync = ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Projects", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
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
                  
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(project: project),
                      )
                    );
                  },
                  
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "join_btn",
            backgroundColor: AppColors.surface, 
            onPressed: () => _showJoinDialog(context, ref),
            icon: const Icon(Icons.link, color: Colors.white),
            label: const Text("Join Project", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 16),
          
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

                await ref.read(projectRepositoryProvider).joinProject(
                  inviteCode: code, 
                  userId: user.uid
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Successfully joined!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx); 
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