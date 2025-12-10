import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const ChatScreen({
    super.key,
    required this.projectId,
    this.projectName = 'Project Chat',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to send messages.')),
        );
        return;
      }

      final message = ChatMessage(
        id: '',
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        text: _controller.text.trim(),
        timestamp: DateTime.now(),
      );

      ref.read(chatRepositoryProvider).sendMessage(widget.projectId, message);
      _controller.clear();
    } catch (e) {
      log('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsyncValue = ref.watch(chatStreamProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(widget.projectName),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatAsyncValue.when(
              data: (messages) {
                if (FirebaseAuth.instance.currentUser == null) {
                  return const Center(child: Text('Please log in to view messages.'));
                }
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  reverse: true, // Show newest at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == FirebaseAuth.instance.currentUser?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg.senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              spacing: 4.0,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton.filled(
                  color: Theme.of(context).colorScheme.onPrimary,
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
