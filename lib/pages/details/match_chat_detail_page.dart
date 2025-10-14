import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/match_chat_service.dart';
import '../../providers/authentication_provider.dart';
import '../../services/ai_message_service.dart';
import '../../widgets/chat/chat_app_bar.dart';
import '../../widgets/chat/messages_list_view.dart';
import '../../widgets/chat/ai_suggestions_panel.dart';
import '../../widgets/chat/message_input_bar.dart';
import '../../theme/app_theme.dart';

class MatchChatDetailPage extends StatefulWidget {
  const MatchChatDetailPage({super.key});

  @override
  State<MatchChatDetailPage> createState() => _MatchChatDetailPageState();
}

class _MatchChatDetailPageState extends State<MatchChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isAIGenerating = false;
  bool _isAIEnabled = false;
  List<String> _aiSuggestions = [];
  late final AIMessageService _aiMessageService;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);

    // Initialize AIMessageService
    _aiMessageService = AIMessageService();
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Trigger rebuild when text changes to update send button state
    setState(() {});
  }

  Future<void> _sendMessage(
    String matchId,
    String otherUserName,
    String? currentUserId,
  ) async {
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
      debugPrint(
        '❌ BLOCKED: message.isEmpty=${message.isEmpty}, _isSending=$_isSending, currentUserId=$currentUserId',
      );
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

    // Set sending state
    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      debugPrint('🔄 Calling MatchChatService.sendMessage...');

      // Add timeout to prevent hanging
      await MatchChatService.sendMessage(
        matchId: matchId,
        senderId: currentUserId,
        message: message,
        senderName: null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Send message timeout');
        },
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

      // // Show success message (brief)
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('✅ Đã gửi tin nhắn'),
      //       duration: Duration(seconds: 1),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      // }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR SENDING MESSAGE');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('═══════════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi gửi tin nhắn: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Always reset sending state
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _generateAISuggestions(
    String matchId,
    String otherUserName,
    String? currentUserId,
  ) async {
    if (!_isAIEnabled || _isAIGenerating || currentUserId == null) {
      return;
    }

    setState(() {
      _isAIGenerating = true;
    });

    try {
      // Get recent messages for context
      final messagesQuery = FirebaseFirestore.instance
          .collection('messages')
          .where('matchId', isEqualTo: matchId)
          .orderBy('timestamp', descending: true)
          .limit(10);

      final messagesSnapshot = await messagesQuery.get();
      final recentMessages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'text': data['text'] ?? '',
          'isMe': data['senderId'] == currentUserId,
          'timestamp': data['timestamp'],
        };
      }).toList();

      // Generate suggestions
      final result = await _aiMessageService.generateMessageSuggestions(
        recentMessages: recentMessages,
        otherUserName: otherUserName,
        maxSuggestions: 3,
      );

      if (mounted && result != null) {
        setState(() {
          _aiSuggestions = List<String>.from(result['suggestions'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('❌ Error generating AI suggestions: $e');
      if (mounted) {
        // Fallback suggestions
        setState(() {
          _aiSuggestions = _aiMessageService.getFallbackSuggestions(
            otherUserName,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAIGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.userId;
        final isPremium = authProvider.isRizzPlus;

        // Log để debug
        debugPrint('🔑 MatchChatDetail - Current User ID: $currentUserId');
        debugPrint('👑 Is Premium: $isPremium');

        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        if (args == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tin nhắn')),
            body: const Center(
              child: Text('Không tìm thấy thông tin cuộc trò chuyện'),
            ),
          );
        }

        final matchId = args['matchId'] as String;
        final otherUserName = args['otherUserName'] as String;
        final otherUserAvatar = args['otherUserAvatar'] as String?;

        // Mark messages as read when user ID is available
        if (currentUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MatchChatService.markMessagesAsRead(matchId, currentUserId);
          });
        }

        return Scaffold(
          appBar: ChatAppBar(
            otherUserName: otherUserName,
            otherUserAvatar: otherUserAvatar,
            isPremium: isPremium,
            isAIEnabled: _isAIEnabled,
            onAIToggle: () {
              setState(() {
                _isAIEnabled = !_isAIEnabled;
                if (!_isAIEnabled) {
                  _aiSuggestions.clear();
                }
              });
            },
            onUnmatch: () => _showUnmatchDialog(matchId, otherUserName),
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: MessagesListView(
                  matchId: matchId,
                  currentUserId: currentUserId,
                  otherUserAvatar: otherUserAvatar,
                  otherUserName: otherUserName,
                  scrollController: _scrollController,
                ),
              ),

              // AI Suggestions (only show for premium users when AI is enabled)
              if (isPremium && _isAIEnabled && _aiSuggestions.isNotEmpty)
                AISuggestionsPanel(
                  suggestions: _aiSuggestions,
                  isGenerating: _isAIGenerating,
                  onRefresh: () => _generateAISuggestions(
                    matchId,
                    otherUserName,
                    currentUserId,
                  ),
                  onSuggestionTap: (suggestion) {
                    _messageController.text = suggestion;
                    setState(() {});
                  },
                ),

              // Message input
              MessageInputBar(
                controller: _messageController,
                isSending: _isSending,
                isPremium: isPremium,
                isAIEnabled: _isAIEnabled,
                isAIGenerating: _isAIGenerating,
                onSend: () =>
                    _sendMessage(matchId, otherUserName, currentUserId),
                onAISuggest: () => _generateAISuggestions(
                  matchId,
                  otherUserName,
                  currentUserId,
                ),
                authProvider: authProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUnmatchDialog(String matchId, String otherUserName) {
    final currentContext = context; // Store context to avoid async gap issues
    showDialog(
      context: currentContext,
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
                    Navigator.of(currentContext).pop(); // Go back to chat list
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(content: Text('Đã hủy kết nối')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      currentContext,
                    ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: context.error),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
}
