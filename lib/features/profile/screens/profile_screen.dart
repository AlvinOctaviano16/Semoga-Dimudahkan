import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil Stream Data User dari Repository
    final userStream = ref.watch(authRepositoryProvider).getUserData();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snapshot) {
          // Handling Loading & Error
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data user tidak ditemukan."));
          }

          // 2. Tampilkan Data (READ)
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'No Name';
          final email = data['email'] ?? '-';

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: 20),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 30),
                
                // 3. Tombol Edit (UPDATE)
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Nama"),
                  onPressed: () {
                    _showEditDialog(context, ref, name);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Dialog Kecil untuk Edit Nama
  void _showEditDialog(BuildContext context, WidgetRef ref, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              // Panggil Fungsi Update di Repository
              await ref.read(authRepositoryProvider).updateProfile(name: nameController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}