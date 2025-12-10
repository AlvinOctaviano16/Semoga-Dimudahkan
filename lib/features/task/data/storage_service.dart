import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageRepository {
  // Constructor kosong karena tidak butuh FirebaseStorage
  StorageRepository();

  Future<String> uploadImageProof(File file, String taskId) async {
    try {
      // 1. Baca file gambar sebagai bytes
      final bytes = await file.readAsBytes();
      
      // 2. Ubah menjadi String Base64
      String base64Image = base64Encode(bytes);
      
      // 3. Kembalikan string tersebut (ini yang akan disimpan di 'proofUrl')
      return base64Image;
    } catch (e) {
      throw Exception("Gagal mengkonversi gambar: $e");
    }
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});