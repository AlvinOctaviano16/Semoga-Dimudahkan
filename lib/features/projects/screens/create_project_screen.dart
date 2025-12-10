import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
// Import Model agar bisa terima data
import '../models/project_model.dart'; 

class CreateProjectScreen extends ConsumerStatefulWidget {
  // Tambahkan parameter opsional ini
  final ProjectModel? projectToEdit; 

  const CreateProjectScreen({super.key, this.projectToEdit});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // LOGIKA PENTING:
    // Jika ada data projectToEdit, isi form dengan data lama (Mode Edit)
    if (widget.projectToEdit != null) {
      _nameController.text = widget.projectToEdit!.name;
      _descController.text = widget.projectToEdit!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      const fakeUserId = "user-bypass-123"; 

      // CEK MODE: EDIT atau CREATE?
      if (widget.projectToEdit != null) {
        // --- MODE EDIT ---
        await ref.read(projectRepositoryProvider).updateProject(
          projectId: widget.projectToEdit!.id, // Pakai ID lama
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
        );
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyek berhasil diperbarui! ✅'), backgroundColor: Colors.blue),
        );
      } else {
        // --- MODE CREATE ---
        await ref.read(projectRepositoryProvider).createProject(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          ownerId: fakeUserId,
        );
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyek berhasil dibuat! 🚀'), backgroundColor: Colors.green),
        );
      }

      if (!mounted) return;
      Navigator.pop(context); 

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ubah Judul App Bar sesuai mode
    final isEditing = widget.projectToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Proyek" : "Buat Proyek Baru"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Proyek',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Singkat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? Colors.orange : Colors.blue, // Beda warna biar keren
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Simpan Perubahan' : 'Buat Proyek'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}