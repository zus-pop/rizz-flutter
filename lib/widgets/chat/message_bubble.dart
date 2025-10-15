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
              backgroundColor: context.surface.withValues(
                alpha: 0.5,
              ), // Use theme surface color
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null && widget.userName != null
                  ? Text(
                      widget.userName![0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.onSurface, // Use theme text color
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
                          color: context.onSurface.withValues(
                            alpha: 0.6,
                          ), // Use theme color with alpha
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
                          : context
                                .surface, // Use theme surface color instead of white
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                      ),
                      border: Border.all(
                        color: context.onSurface.withValues(alpha: 0.5),
                        width: 0.5,
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
                            : context
                                  .onSurface, // Use theme text color instead of grey
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
                          color: context.onSurface.withValues(
                            alpha: 0.6,
                          ), // Use theme color
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
