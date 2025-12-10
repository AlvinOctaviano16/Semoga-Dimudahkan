import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class StorageRepository{
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  Future<String> uploadImageProof(File file, String taskId) async{
    final fileName='proofs/$taskId/${const Uuid().v4()}.jpg';
    final ref=_storage.ref().child(fileName);

    final uploadTask=ref.putFile(file);
    final snapshot=await uploadTask.whenComplete(() {});

    final downloadUrl= await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(FirebaseStorage.instance);
});

