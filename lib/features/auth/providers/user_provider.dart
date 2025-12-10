import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// Stream Provider: Otomatis update UI kalau data di Firestore berubah
final userProfileProvider = StreamProvider<DocumentSnapshot>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getUserData();
});