import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

// Simple animated typing indicator widget
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
    _dotCount = StepTween(
      begin: 1,
      end: 3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        String dots = '.' * _dotCount.value;
        return Text(
          'Đang trả lời$dots',
          style: TextStyle(
            color:
                Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.black54,
            fontSize: 15,
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}

class StructureOutput {
  final String message;
  final int score;

  StructureOutput({required this.message, required this.score});

  StructureOutput.fromJson(Map<String, dynamic> json)
    : message = json['message'] as String,
      score = json['score'] as int;
}

class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final int score;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.score = 0,
  });

  ChatMessage copyWith({String? message, int? score, bool? isPositive}) {
    return ChatMessage(
      id: id,
      message: message ?? this.message,
      isUser: isUser,
      timestamp: timestamp,
      score: score ?? this.score,
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
  int _userScore = 10;

  int? _lastScoreChange; // For animation
  bool _scoreChanged = false;
  bool _gameOver = false;

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
    final jsonSchema = Schema.object(
      properties: {
        'message': Schema.string(
          description: "Phản hồi cho đối phương",
          nullable: false,
        ),
        'score': Schema.number(
          description:
              "Điểm số dành cho đối phương dựa vào tin nhắn của họ, đối phương có tổng điểm là $_userScore, nếu như là điểm cộng thì sẽ là số dương ngược lại điểm trừ sẽ là số âm, nếu như ko phải 2 trường hợp trước đó thì sẽ là trung tính không cộng không trừ",
          nullable: false,
        ),
      },
    );
    _model = FirebaseAI.vertexAI(location: 'global').generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: jsonSchema,
      ),
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
7. Nếu có thông tin nào trong hồ sơ, hãy sử dụng nó để làm cho câu trả lời trở nên cá nhân hóa và chân thực nhất có thể, tuy nhiên đừng có cứng nhắc quá về việc mang hết tất cả vào tin nhắn, hãy sử dụng thông tin của hồ sơ một cách tinh tế.
8. Khi giới thiệu về bản thân, không nên nói ra hết tất cả, hãy nói 1 phần nhỏ để đối phương chủ động đào sâu vào thêm
9. Hãy dựa vào nhưng tin nhắn của đối phương để dự đoán tính cách của họ liệu có nên tiếp tục nhắn tin hay không đặc biệt nếu như hồ sơ này là giới tính nữ thì đừng tích cực hỏi họ mà phải để họ chủ động
10. Không cần lúc nào cũng phải xưng hô lịch sự, nếu đối phương tỏ ra thái độ bố láo thì mình bố láo luôn, có thể áp dụng ngôn ngữ của GenZ

Không được trả lời quá dài dòng, hãy kiệm lời nhất có thể, hãy để đối phương chủ động mở lời cuộc trò chuyện.
Như một người Việt Nam thực thụ và xưng hô dựa vào đối phương gọi xưng hô như thế nào.
''';
  }

  // English prompt removed. Using Vietnamese prompt via _buildCharacterPromptVN().

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping || _gameOver) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });

    _controller.clear();
    _scrollToBottom();
    await Future.delayed(Duration(seconds: Random().nextInt(5) + 1));
    setState(() {
      _isTyping = true;
    });
    try {
      // Send message and get response (not streaming)
      final response = await _chatSession.sendMessage(Content.text(text));
      final structureOutput = StructureOutput.fromJson(
        json.decode(response.text ?? '{"message": "Error", "score":"0"}'),
      );
      setState(() {
        _lastScoreChange = structureOutput.score;
        _userScore += structureOutput.score;
        _scoreChanged = true;
      });
      // Reset score change animation after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _scoreChanged = false);
      });
      // Simulate a structure: message, score, isPositive
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        message: structureOutput.message,
        isUser: false,
        timestamp: DateTime.now(),
        score: structureOutput.score,
      );
      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
      _scrollToBottom();
      // Check for game over AFTER AI message is shown
      if (_userScore <= 0 && !_gameOver) {
        setState(() {
          _gameOver = true;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              title: const Text('Game Over'),
              content: const Text(
                'Your score is below or equal zero. You can review your chat history or restart the game when ready.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        return;
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
            message: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
      debugPrint('Error sending message: $e');
    }
  }

  void _restartGame() {
    setState(() {
      _userScore = 10;
      _messages.clear();
      _gameOver = false;
      _scoreChanged = false;
      _lastScoreChange = null;
      _isTyping = false;
    });
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
      ),
      body: Column(
        children: [
          // User score display
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _scoreChanged
                    ? (_lastScoreChange ?? 0) > 0
                          ? Colors.green.withValues(alpha: .15)
                          : (_lastScoreChange ?? 0) < 0
                          ? Colors.red.withValues(alpha: .15)
                          : context.colors.surfaceContainer
                    : context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, color: context.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Score: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.onSurface,
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: _scoreChanged
                          ? (_lastScoreChange ?? 0) > 0
                                ? Colors.green
                                : (_lastScoreChange ?? 0) < 0
                                ? Colors.red
                                : context.primary
                          : context.primary,
                    ),
                    child: Text('$_userScore'),
                  ),
                  if (_scoreChanged && (_lastScoreChange ?? 0) != 0) ...[
                    const SizedBox(width: 8),
                    AnimatedOpacity(
                      opacity: _scoreChanged ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Row(
                        children: [
                          Icon(
                            (_lastScoreChange ?? 0) > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: (_lastScoreChange ?? 0) > 0
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          Text(
                            (_lastScoreChange ?? 0) > 0
                                ? '+$_lastScoreChange'
                                : '$_lastScoreChange',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: (_lastScoreChange ?? 0) > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8.0,
                left: 24.0,
                right: 24.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: context.colors.onPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _TypingIndicator(),
                ],
              ),
            ),
          _buildInputArea(),
          if (_gameOver)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 4.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Restart Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _restartGame,
              ),
            ),
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
                  Text(
                    message.message.isEmpty ? '...' : message.message,
                    style: TextStyle(
                      color: message.isUser
                          ? context.colors.onPrimary
                          : context.onSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (!message.isUser) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('Score: ${message.score}')],
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
                    enabled: !_isTyping && !_gameOver,
                    decoration: InputDecoration(
                      hintText: _gameOver
                          ? 'Game over! Please restart.'
                          : _isTyping
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
                  color:
                      _controller.text.trim().isEmpty || _isTyping || _gameOver
                      ? context.colors.surfaceContainer
                      : context.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color:
                        _controller.text.trim().isEmpty ||
                            _isTyping ||
                            _gameOver
                        ? context.onSurface.withValues(alpha: 0.5)
                        : context.colors.onPrimary,
                  ),
                  onPressed:
                      _controller.text.trim().isEmpty || _isTyping || _gameOver
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

// ...streaming animation widget removed (no longer needed)...
