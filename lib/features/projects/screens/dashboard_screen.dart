import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/screens/profile_screen.dart';
import '../providers/project_provider.dart';
import '../repositories/project_repository.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
// 👇 Tambahkan import ini untuk mengambil Nama User di Header
import '../../auth/providers/user_provider.dart'; 

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

  // 👇 LOGIKA ASLI KAMU (TETAP UTUH)
  Future<void> _syncUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await user.reload();
        user = FirebaseAuth.instance.currentUser; 
        
        if (user == null) return;

        print("🔍 Syncing User: ${user.email}");

        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        final Map<String, dynamic> updates = {
          'lastActive': FieldValue.serverTimestamp(),
        };

        if (user.email != null) {
          updates['email'] = user.email; 
        }

        final token = await NotificationService().getToken();
        if (token != null) {
          updates['fcmToken'] = token;
        }

        await userDocRef.set(updates, SetOptions(merge: true));
        print("✅ Data User berhasil disinkronisasi (Email & Token)");
        
      } catch (e) {
        print("⚠️ Gagal sinkronisasi user: $e");
      }
    }
  }

  // Helper Sapaan Waktu
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final projectListAsync = ref.watch(projectListProvider);
    // 👇 Watch User Profile untuk Header
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // 👇 UPDATE 1: HEADER PERSONAL
        toolbarHeight: 80, // Agak tinggi biar muat 2 baris
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: userProfileAsync.when(
          loading: () => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text("Welcome,", style: TextStyle(color: Colors.grey, fontSize: 14)),
               Text("Loading...", style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          error: (_, __) => const Text("Hello, User", style: TextStyle(color: Colors.white)),
          data: (snapshot) {
            final data = snapshot.data() as Map<String, dynamic>?;
            final name = data?['name'] ?? 'User';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 20, // Sedikit diperbesar
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person, size: 24, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          const SizedBox(width: 16),
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
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              // 👇 Cek Owner
              final isOwner = project.ownerId == currentUid;

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Radius diperhalus
                child: InkWell( // Pakai InkWell biar ada efek ripple saat klik
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(project: project),
                      )
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Icon Project
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          radius: 24,
                          child: Text(
                            project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Info Project
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name, 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              const SizedBox(height: 4),
                              
                              // 👇 UPDATE 2: INFO OWNER DI BAWAH JUDUL
                              Row(
                                children: [
                                  Icon(
                                    isOwner ? Icons.verified_user : Icons.group, 
                                    size: 12, 
                                    color: isOwner ? Colors.greenAccent : Colors.grey
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOwner ? "Created by: You" : "Created by: Team Lead",
                                    style: TextStyle(
                                      color: isOwner ? Colors.greenAccent : Colors.grey, 
                                      fontSize: 12
                                    )
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 6),
                              Text(
                                project.description, 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // 👇 FAB ASLI KAMU (TETAP UTUH)
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