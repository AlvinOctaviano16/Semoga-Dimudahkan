import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Opsional: Untuk format tanggal jika ada

// Import Provider & Screen Create
import '../providers/project_provider.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

// Kita pakai ConsumerWidget agar bisa mendengar (listen) perubahan data Provider
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH: Ini kuncinya. UI akan otomatis rebuild jika data di Firebase berubah.
    final projectListAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Proyek"),
        centerTitle: false, // Gaya Android modern (rata kiri)
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {}, // Nanti untuk notifikasi
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {}, // Nanti untuk profil
          ),
        ],
      ),

      // 2. BODY: Menangani 3 Kondisi (Loading, Error, Data)
      body: projectListAsync.when(
        // 1. KONDISI LOADING (Hanya muncul saat awal buka)
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Memuat proyek..."),
            ],
          ),
        ),

        // 2. KONDISI ERROR
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Terjadi error: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),

        // 3. KONDISI ADA DATA (Bisa Kosong, Bisa Ada Isinya)
        data: (projects) {
          // A. JIKA KOSONG (Empty State)
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ikon Besar
                  Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada proyek",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  // Tombol ajakan membuat proyek
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Buat Proyek Pertama"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  )
                ],
              ),
            );
          }

          // B. JIKA ADA DATA -> TAMPILKAN LIST
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(project.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(project: project),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Membuka ${project.name}...")),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // 3. Tombol Tambah (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigasi ke Halaman Create
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
          );
        },
        label: const Text("Add Project"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}