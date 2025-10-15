import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/match_chat_service.dart';
import '../../providers/authentication_provider.dart';
import '../../theme/app_theme.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with AutomaticKeepAliveClientMixin<Chat> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Lấy currentUserId từ AuthenticationProvider giống như profile.dart
    final authProvider = context.watch<AuthenticationProvider>();
    final currentUserId = authProvider.userId;

    // Log để debug
    debugPrint('═══════════════════════════════════════');
    debugPrint('Chat Tab - Current User ID: $currentUserId');
    debugPrint('═══════════════════════════════════════');

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tin Nhắn'),
          backgroundColor: Colors.pink,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Vui lòng đăng nhập để xem tin nhắn',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin Nhắn'),
        backgroundColor: context.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: MatchChatService.getUserMatchesStream(currentUserId),
        builder: (context, snapshot) {
          // Log chi tiết về snapshot
          debugPrint('─────────────────────────────────────');
          debugPrint('StreamBuilder State:');
          debugPrint('- ConnectionState: ${snapshot.connectionState}');
          debugPrint('- HasData: ${snapshot.hasData}');
          debugPrint('- HasError: ${snapshot.hasError}');
          if (snapshot.hasError) {
            debugPrint('- Error: ${snapshot.error}');
            debugPrint('- Error Type: ${snapshot.error.runtimeType}');
          }
          if (snapshot.hasData) {
            debugPrint('- Docs Count: ${snapshot.data!.docs.length}');
            for (var doc in snapshot.data!.docs) {
              debugPrint('  * Match ID: ${doc.id}');
              debugPrint('  * Data: ${doc.data()}');
            }
          }
          debugPrint('─────────────────────────────────────');

          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            final isMissingIndex =
                error.contains('index') ||
                error.contains('FAILED_PRECONDITION');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isMissingIndex ? Icons.warning : Icons.error_outline,
                      size: 64,
                      color: isMissingIndex
                          ? AppTheme.secondary(context)
                          : context.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isMissingIndex
                          ? 'Cần tạo Firestore Index'
                          : 'Lỗi kết nối',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMissingIndex
                            ? AppTheme.secondary(context)
                            : context.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMissingIndex
                          ? 'Vui lòng tạo Firestore Index trong Firebase Console'
                          : 'Không thể tải danh sách tin nhắn',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (isMissingIndex)
                      const Text(
                        'Xem terminal để lấy link tạo index',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    // Show detailed error
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        'Chi tiết lỗi:\n$error',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: context.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách tin nhắn...'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint('⚠️ No matches found for user: $currentUserId');

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: context.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: context.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy match với ai đó để bắt đầu chat!',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User ID: $currentUserId',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.onSurface.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            );
          }

          final matches = snapshot.data!.docs;
          debugPrint('✅ Displaying ${matches.length} matches');

          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final matchDoc = matches[index];
              final matchData = matchDoc.data() as Map<String, dynamic>;
              final matchId = matchDoc.id;

              debugPrint('Building match item #$index: $matchId');

              // Get the other user ID
              final otherUserId = MatchChatService.getOtherUserId(
                matchId,
                currentUserId,
              );

              return _buildMatchItem(
                context,
                matchId,
                otherUserId,
                matchData,
                currentUserId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchItem(
    BuildContext context,
    String matchId,
    String otherUserId,
    Map<String, dynamic> matchData,
    String currentUserId,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: context.surface.withValues(alpha: 0.5),
              child: Icon(
                Icons.person,
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            title: const Text('Đang tải...'),
            subtitle: const Text(''),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

        // Build full name from firstName and lastName
        final firstName = userData?['firstName'] as String? ?? '';
        final lastName = userData?['lastName'] as String? ?? '';
        final email = userData?['email'] as String?;

        String userName = '$firstName $lastName'.trim();
        if (userName.isEmpty) {
          // Fallback to email username if name is not available
          userName = email?.split('@').first ?? 'Người dùng';
        }

        // Get avatar from imageUrls array (first image)
        final imageUrls = userData?['imageUrls'] as List<dynamic>?;
        final userAvatar = (imageUrls != null && imageUrls.isNotEmpty)
            ? imageUrls[0] as String?
            : null;

        // Get last message info with type support
        final lastMessageType = matchData['lastMessageType'] as String?;
        final lastMessage = matchData['lastMessage'] as String?;
        final lastMessageAt = matchData['lastMessageAt'] as Timestamp?;

        // Display message based on type
        final displayMessage = lastMessageType == 'voice'
            ? '🎤 Tin nhắn thoại'
            : (lastMessage ?? 'Chưa có tin nhắn');

        // Debug log
        debugPrint('👤 Match #$matchId:');
        debugPrint('   - Other User ID: $otherUserId');
        debugPrint('   - FirstName: $firstName');
        debugPrint('   - LastName: $lastName');
        debugPrint('   - Display Name: $userName');
        debugPrint('   - Avatar: $userAvatar');
        debugPrint('   - Last Message Type: $lastMessageType');
        debugPrint('   - Display Message: $displayMessage');

        return FutureBuilder<int>(
          future: MatchChatService.getUnreadMessageCount(
            matchId,
            currentUserId,
          ),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;

            return ListTile(
              leading: Stack(
                children: [
                  _buildAvatar(userName, userAvatar),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                userName,
                style: TextStyle(
                  fontWeight: unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: context.onSurface,
                ),
              ),
              subtitle: Text(
                displayMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unreadCount > 0
                      ? context.onSurface
                      : context.onSurface.withValues(alpha: 0.7),
                  fontWeight: unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastMessageAt != null)
                    Text(
                      _formatTimestamp(lastMessageAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: unreadCount > 0
                            ? context.primary
                            : context.onSurface.withValues(alpha: 0.6),
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/match_chat_detail',
                  arguments: {
                    'matchId': matchId,
                    'otherUserId': otherUserId,
                    'otherUserName': userName,
                    'otherUserAvatar': userAvatar,
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Build avatar with error handling
  Widget _buildAvatar(String userName, String? avatarUrl) {
    // Get first letter for fallback
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    // Generate a color based on userName for consistency
    final colorIndex = userName.hashCode.abs() % Colors.primaries.length;
    final backgroundColor = Colors.primaries[colorIndex].shade300;

    if (avatarUrl == null || avatarUrl.isEmpty) {
      // No avatar URL - show letter
      return CircleAvatar(
        radius: 28,
        backgroundColor: backgroundColor,
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Has avatar URL - try to load with error handling
    return CircleAvatar(
      radius: 28,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          errorWidget: (context, url, error) {
            // Image failed to load - show letter fallback
            debugPrint('⚠️ Avatar load failed: $error');
            debugPrint('   URL: $avatarUrl');
            return Container(
              width: 56,
              height: 56,
              color: backgroundColor,
              child: Center(
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    fontSize: 24,
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

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
