import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/match_chat_service.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/voice_message_bubble.dart';

class MessagesListView extends StatelessWidget {
  final String matchId;
  final String? currentUserId;
  final String? otherUserAvatar;
  final String otherUserName;
  final ScrollController scrollController;

  const MessagesListView({
    super.key,
    required this.matchId,
    required this.currentUserId,
    required this.otherUserAvatar,
    required this.otherUserName,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: MatchChatService.getMessagesStream(matchId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        // Show empty state initially or when no messages
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có tin nhắn',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy gửi tin nhắn đầu tiên!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageDoc = messages[index];
            final messageData = messageDoc.data() as Map<String, dynamic>;
            final senderId = messageData['senderId'] as String;
            final text = messageData['text'] as String? ?? '';
            final messageType = messageData['type'] as String? ?? 'text';
            final timestamp = messageData['timestamp'] as Timestamp?;
            final isMe = senderId == currentUserId;

            // Check if it's a voice message
            if (messageType == 'voice') {
              final voiceUrl = messageData['voiceUrl'] as String?;
              final duration = messageData['duration'] as int?;

              if (voiceUrl != null) {
                return VoiceMessageBubble(
                  voiceUrl: voiceUrl,
                  duration: duration,
                  isMe: isMe,
                  timestamp: timestamp,
                  showAvatar: !isMe,
                  avatarUrl: !isMe ? otherUserAvatar : null,
                  userName: !isMe ? otherUserName : null,
                );
              }
            }

            // Regular text message
            return MessageBubble(
              text: text,
              isMe: isMe,
              timestamp: timestamp,
              showAvatar: !isMe,
              avatarUrl: !isMe ? otherUserAvatar : null,
              userName: !isMe ? otherUserName : null,
            );
          },
        );
      },
    );
  }
}
