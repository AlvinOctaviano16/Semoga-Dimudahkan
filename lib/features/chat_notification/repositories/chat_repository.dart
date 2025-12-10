import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  Stream<List<ChatMessage>> getChatStream(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendMessage(String projectId, ChatMessage message) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .add(message.toMap());
  }
}
