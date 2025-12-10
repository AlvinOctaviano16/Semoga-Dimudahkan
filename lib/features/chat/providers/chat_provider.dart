import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../domain/chat_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

// Stream Chat (Auto Dispose biar tidak bocor memori)
final chatStreamProvider = StreamProvider.family.autoDispose<List<ChatMessage>, String>((ref, projectId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatStream(projectId);
});