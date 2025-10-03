import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rizz_mobile/models/chat_models.dart';
import 'package:rizz_mobile/services/firebase_chat_service.dart';

class FirebaseDetailChat extends StatefulWidget {
  final String chatRoomId;
  final String chatRoomName;
  final String? chatRoomDescription;

  const FirebaseDetailChat({
    super.key,
    required this.chatRoomId,
    required this.chatRoomName,
    this.chatRoomDescription,
  });

  @override
  State<FirebaseDetailChat> createState() => _FirebaseDetailChatState();
}

class _FirebaseDetailChatState extends State<FirebaseDetailChat>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isTyping = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _setupMessageListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _initializeChat() {
    _currentUserId = FirebaseChatService.getCurrentUserId();
  }

  void _setupMessageListener() {
    _messageController.addListener(() {
      final isTyping = _messageController.text.trim().isNotEmpty;
      if (isTyping != _isTyping) {
        setState(() {
          _isTyping = isTyping;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseChatService.sendMessage(
        widget.chatRoomId,
        text,
      );

      _messageController.clear();
      
      // Auto scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _showErrorSnackBar('❌ Không thể gửi tin nhắn: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(message.senderName),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && widget.chatRoomName.contains('Nhóm'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe 
                          ? Colors.white.withValues(alpha: 0.8) 
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(message.senderName, isMe: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, {bool isMe = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isMe 
              ? [Colors.pink.shade300, Colors.pink.shade500]
              : [Colors.blue.shade300, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}p';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có tin nhắn nào',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy bắt đầu cuộc trò chuyện!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Có lỗi xảy ra',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _messageFocusNode.hasFocus 
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.chat_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isLoading,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isTyping 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isLoading || !_isTyping ? null : _sendMessage,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: _isTyping ? Colors.white : Colors.grey.shade500,
                        size: 20,
                      ),
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoomName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.chatRoomDescription?.isNotEmpty == true)
              Text(
                widget.chatRoomDescription!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Show room info, participants, etc.
              _showSuccessSnackBar('🔧 Tính năng đang phát triển');
            },
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Thông tin phòng',
          ),
          IconButton(
            onPressed: () {
              // TODO: More options
              _showSuccessSnackBar('⚙️ Tùy chọn khác');
            },
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Tùy chọn',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseChatService.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final messages = snapshot.data?.docs.map((doc) {
                  return ChatMessage.fromFirestore(doc);
                }).toList() ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Newest messages at bottom
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }
}