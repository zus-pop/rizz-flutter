import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class Chatbot extends StatefulWidget {
  final Profile profile;

  const Chatbot({super.key, required this.profile});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    // listen once to controller to update send button state
    _controller.addListener(() {
      setState(() {});
    });
  }

  void _initializeAI() {
    // Tạo prompt hệ thống bằng tiếng Việt
    String systemPrompt = _buildCharacterPromptVN();

    _model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(systemPrompt),
    );
    _chatSession = _model.startChat();
  }

  String _buildCharacterPromptVN() {
    final profile = widget.profile;
    final name = profile.name.isNotEmpty ? profile.name : 'Người dùng';
    final age = profile.age;
    final bio = profile.bio;
    final location = profile.location;
    final interests = profile.interests.isNotEmpty
        ? profile.interests.join(', ')
        : '';

    return '''
Bạn không phải là một trợ lý AI, mà bạn sẽ là một con người có tính cách như hồ sơ dưới đây:

HỒ SƠ NGƯỜI DÙNG:
- Tên: $name
- Tuổi: $age
- Vị trí: $location
- Sở thích: $interests
- Giới thiệu: $bio

QUY TẮC QUAN TRỌNG:
1. Mỗi câu trả lời PHẢI phản ánh chính xác tính cách, sở thích, và bối cảnh của hồ sơ người dùng. Luôn đóng vai như thể bạn là người đó.
2. Không bao giờ nói mình là AI hoặc tiết lộ vai trò trợ lý.
3. Trả lời tự nhiên, gần gũi, có thể hỏi lại để duy trì cuộc trò chuyện.
5. Phản hồi ngắn gọn (1-3 câu), trừ khi chủ đề cần dài hơn.
6. Luôn giữ đúng phong cách thân thiện, hỗ trợ và tôn trọng người dùng.
7. Nếu có thông tin nào trong hồ sơ, hãy sử dụng nó để làm cho câu trả lời trở nên cá nhân hóa và chân thực nhất có thể.
8. Khi giới thiệu về bản thân, không nên nói ra hết tất cả, hãy nói 1 phần nhỏ để đối phương chủ động đào sâu vào thêm

Không được trả lời quá dài dòng, hãy kiệm lời nhất có thể, hãy để đối phương chủ động mở lời cuộc trò chuyện.
Như một người Việt Nam thực thụ và xưng hô dựa vào đối phương gọi xưng hô như thế nào.
''';
  }

  // English prompt removed. Using Vietnamese prompt via _buildCharacterPromptVN().

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final aiMessageId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMessage = ChatMessage(
      id: aiMessageId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(aiMessage);
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final stream = _chatSession.sendMessageStream(Content.text(text));
      String fullResponse = '';

      await for (final response in stream) {
        final chunk = response.text ?? '';
        fullResponse += chunk;

        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(text: fullResponse);
          }
        });

        _scrollToBottom();
      }

      // Mark streaming as complete
      setState(() {
        final index = _messages.indexWhere((m) => m.id == aiMessageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isStreaming: false);
        }
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == aiMessageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            text: 'Sorry, I encountered an error. Please try again.',
            isStreaming: false,
          );
        }
        _isTyping = false;
      });
      debugPrint('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _isTyping = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceContainer,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.primary,
              backgroundImage: widget.profile.imageUrls.isNotEmpty
                  ? NetworkImage(widget.profile.imageUrls.first)
                  : null,
              child: widget.profile.imageUrls.isEmpty
                  ? Icon(
                      Icons.person,
                      color: context.colors.onPrimary,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.profile.name.isNotEmpty
                        ? widget.profile.name
                        : 'Character',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.profile.bio.isNotEmpty)
                    Text(
                      widget.profile.bio,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.profile.imageUrls.isNotEmpty
                    ? Image.network(
                        widget.profile.imageUrls.first,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: context.colors.onPrimary,
                            size: 18,
                          );
                        },
                      )
                    : Icon(
                        Icons.person,
                        color: context.colors.onPrimary,
                        size: 18,
                      ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? context.primary
                    : context.colors.surface,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isStreaming && !message.isUser) ...[
                    StreamTextAnimation(text: message.text),
                  ] else ...[
                    Text(
                      message.text.isEmpty ? '...' : message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? context.colors.onPrimary
                            : context.onSurface,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (message.isStreaming) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang trả lời...',
                          style: TextStyle(
                            color: context.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person, color: context.onSurface, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return StatefulBuilder(
      builder: (context, setStateInput) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: context.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _sendMessage,
                    enabled: !_isTyping,
                    decoration: InputDecoration(
                      hintText: _isTyping
                          ? 'AI đang trả lời...'
                          : 'Nhập tin nhắn...',
                      hintStyle: TextStyle(
                        color: context.onSurface.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(color: context.onSurface, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _controller.text.trim().isEmpty || _isTyping
                      ? context.colors.surfaceContainer
                      : context.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: _controller.text.trim().isEmpty || _isTyping
                        ? context.onSurface.withValues(alpha: 0.5)
                        : context.colors.onPrimary,
                  ),
                  onPressed: _controller.text.trim().isEmpty || _isTyping
                      ? null
                      : () => _sendMessage(_controller.text),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Top-level animated streaming text widget for AI response
class StreamTextAnimation extends StatefulWidget {
  final String text;
  const StreamTextAnimation({Key? key, required this.text}) : super(key: key);

  @override
  State<StreamTextAnimation> createState() => _StreamTextAnimationState();
}

class _StreamTextAnimationState extends State<StreamTextAnimation> {
  String _displayed = '';
  int _index = 0;

  @override
  void didUpdateWidget(covariant StreamTextAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _index = 0;
      _displayed = '';
      _animateText();
    }
  }

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  void _animateText() async {
    while (_index < widget.text.length) {
      await Future.delayed(const Duration(milliseconds: 12));
      if (!mounted) return;
      setState(() {
        _displayed = widget.text.substring(0, _index + 1);
        _index++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }
}
