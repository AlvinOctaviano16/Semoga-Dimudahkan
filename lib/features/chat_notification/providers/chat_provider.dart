import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_model.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(firestoreProvider));
});

final chatStreamProvider = StreamProvider.family<List<ChatMessage>, String>((ref, projectId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatStream(projectId);
});
