import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isPremium;
  final bool isAIEnabled;
  final VoidCallback onAIToggle;
  final VoidCallback onUnmatch;

  const ChatAppBar({
    super.key,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.isPremium,
    required this.isAIEnabled,
    required this.onAIToggle,
    required this.onUnmatch,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.primary,
      title: Row(
        children: [
          _buildAvatar(context),
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
        // AI Toggle for Premium Users
        if (isPremium)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: isAIEnabled ? context.onPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onAIToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: isAIEnabled
                            ? context.primary
                            : context.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAIEnabled ? 'AI ON' : 'AI OFF',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAIEnabled
                              ? context.primary
                              : context.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'unmatch') {
              onUnmatch();
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
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final firstLetter = otherUserName.isNotEmpty
        ? otherUserName[0].toUpperCase()
        : '?';
    final colorIndex = otherUserName.hashCode.abs() % Colors.primaries.length;
    final backgroundColor = Colors.primaries[colorIndex].shade300;

    if (otherUserAvatar == null || otherUserAvatar!.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: backgroundColor,
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.onPrimary,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: otherUserAvatar!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          errorWidget: (context, url, error) {
            return Container(
              width: 36,
              height: 36,
              color: backgroundColor,
              child: Center(
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.onPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
