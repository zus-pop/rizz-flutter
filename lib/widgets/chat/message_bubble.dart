import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class MessageBubble extends StatefulWidget {
  final String text;
  final bool isMe;
  final Timestamp? timestamp;
  final bool showAvatar;
  final String? avatarUrl;
  final String? userName;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.timestamp,
    this.showAvatar = false,
    this.avatarUrl,
    this.userName,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  bool _showTimestamp = false;

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
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: widget.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null && widget.userName != null
                  ? Text(
                      widget.userName![0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!widget.isMe)
            const SizedBox(width: 40),
          Flexible(
            child: Dismissible(
              key: UniqueKey(),
              direction: widget.isMe
                  ? DismissDirection
                        .endToStart // Vuốt qua trái cho tin nhắn của tôi
                  : DismissDirection
                        .startToEnd, // Vuốt qua phải cho tin nhắn người khác
              confirmDismiss: (direction) async {
                // Không cho phép xóa, chỉ hiển thị timestamp
                setState(() {
                  _showTimestamp = true;
                });
                // Tự động ẩn sau 2 giây
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _showTimestamp = false;
                    });
                  }
                });
                return false; // Không xóa tin nhắn
              },
              background: Container(
                alignment: widget.isMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                padding: EdgeInsets.only(
                  left: widget.isMe ? 0 : 50,
                  right: widget.isMe ? 20 : 0,
                ),
                child: widget.timestamp != null
                    ? Text(
                        _formatMessageTime(widget.timestamp!),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? context.primary
                          : Colors
                                .white, // Tin nhắn người khác màu trắng nổi bật
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                      ),
                      // Thêm shadow cho tin nhắn người khác để nổi bật hơn
                      boxShadow: !widget.isMe
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.isMe
                            ? context.onPrimary
                            : Colors.grey[900],
                        fontSize: 15,
                      ),
                    ),
                  ),
                  // Hiển thị timestamp khi vuốt
                  if (_showTimestamp && widget.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatMessageTime(widget.timestamp!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
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
}
