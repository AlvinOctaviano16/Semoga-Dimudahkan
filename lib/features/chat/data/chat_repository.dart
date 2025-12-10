import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/chat_model.dart'; // Sesuaikan import

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  // Stream Pesan (Realtime)
  Stream<List<ChatMessage>> getChatStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages') // Subcollection di dalam project
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  // Kirim Pesan
  Future<void> sendMessage(String projectId, ChatMessage message) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .add(message.toMap());
  }
}