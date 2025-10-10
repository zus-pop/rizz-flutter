import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../services/match_chat_service.dart';
import '../../providers/authentication_provider.dart';

class MatchChatDetailPage extends StatefulWidget {
  const MatchChatDetailPage({super.key});

  @override
  State<MatchChatDetailPage> createState() => _MatchChatDetailPageState();
}

class _MatchChatDetailPageState extends State<MatchChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String matchId, String otherUserName, String? currentUserId) async {
    final message = _messageController.text.trim();

    // Debug: Log input values
    debugPrint('═══════════════════════════════════════');
    debugPrint('📤 SENDING MESSAGE');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Match ID: $matchId');
    debugPrint('Current User ID: $currentUserId');
    debugPrint('Message: $message');
    debugPrint('Message Length: ${message.length}');
    debugPrint('Is Empty: ${message.isEmpty}');
    debugPrint('Is Sending: $_isSending');

    if (message.isEmpty || _isSending || currentUserId == null) {
      debugPrint('❌ BLOCKED: message.isEmpty=${message.isEmpty}, _isSending=$_isSending, currentUserId=$currentUserId');
      debugPrint('═══════════════════════════════════════');

      // Show error to user
      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Chưa đăng nhập! Vui lòng đăng nhập lại.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (message.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Vui lòng nhập tin nhắn!')),
          );
        }
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      debugPrint('🔄 Calling MatchChatService.sendMessage...');

      await MatchChatService.sendMessage(
        matchId: matchId,
        senderId: currentUserId,
        message: message,
        senderName: null,
      );

      debugPrint('✅ Message sent successfully!');
      debugPrint('═══════════════════════════════════════');

      _messageController.clear();

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã gửi tin nhắn'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR SENDING MESSAGE');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('═══════════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi gửi tin nhắn: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy currentUserId từ AuthenticationProvider giống như chat.dart
    final authProvider = context.watch<AuthenticationProvider>();
    final currentUserId = authProvider.userId;

    // Log để debug
    debugPrint('🔑 MatchChatDetail - Current User ID: $currentUserId');

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tin nhắn'),
        ),
        body: const Center(
          child: Text('Không tìm thấy thông tin cuộc trò chuyện'),
        ),
      );
    }

    final matchId = args['matchId'] as String;
    final otherUserId = args['otherUserId'] as String;
    final otherUserName = args['otherUserName'] as String;
    final otherUserAvatar = args['otherUserAvatar'] as String?;

    // Mark messages as read when user ID is available
    if (currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MatchChatService.markMessagesAsRead(matchId, currentUserId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Row(
          children: [
            _buildAvatarWidget(otherUserName, otherUserAvatar, radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                otherUserName,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'unmatch') {
                _showUnmatchDialog(matchId, otherUserName);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'unmatch',
                child: Row(
                  children: [
                    Icon(Icons.heart_broken, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hủy kết nối'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: MatchChatService.getMessagesStream(matchId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy gửi tin nhắn đầu tiên!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    final senderId = messageData['senderId'] as String;
                    final text = messageData['text'] as String;
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    final isMe = senderId == currentUserId;

                    return _buildMessageBubble(
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
            ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(matchId, otherUserName, currentUserId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isSending
                          ? null
                          : () => _sendMessage(matchId, otherUserName, currentUserId),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    Timestamp? timestamp,
    bool showAvatar = false,
    String? avatarUrl,
    String? userName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null && userName != null
                  ? Text(
                      userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe)
            const SizedBox(width: 40),

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.pink : Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                    child: Text(
                      _formatMessageTime(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return '${weekdays[date.weekday % 7]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showUnmatchDialog(String matchId, String otherUserName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hủy kết nối'),
          content: Text(
            'Bạn có chắc muốn hủy kết nối với $otherUserName?\n\nTất cả tin nhắn sẽ bị xóa và không thể khôi phục.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                try {
                  await MatchChatService.unmatch(matchId);

                  if (mounted) {
                    Navigator.of(context).pop(); // Go back to chat list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã hủy kết nối'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  /// Build avatar widget with CachedNetworkImage for error handling
  Widget _buildAvatarWidget(String userName, String? avatarUrl, {double radius = 20}) {
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final colorIndex = userName.hashCode.abs() % Colors.primaries.length;
    final backgroundColor = Colors.primaries[colorIndex].shade300;

    if (avatarUrl == null || avatarUrl.isEmpty) {
      // No avatar - show letter
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Has avatar URL - use CachedNetworkImage with error handling
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          errorWidget: (context, url, error) {
            debugPrint('⚠️ Avatar load failed: $error');
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: backgroundColor,
              child: Center(
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
