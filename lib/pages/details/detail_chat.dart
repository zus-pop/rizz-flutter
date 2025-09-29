import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class DetailChat extends StatefulWidget {
  const DetailChat({super.key});

  @override
  State<DetailChat> createState() => _DetailChatState();
}

class _DetailChatState extends State<DetailChat> {
  Socket? socket;
  bool isServer = false;
  final List<String> messages = [];
  final TextEditingController messageController = TextEditingController();
  StreamSubscription? socketSubscription;
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  bool isAITurnOn = false;
  String? aiSuggestion;
  bool isAISuggestionVisible = false;
  bool isAIThinking = false;

  String _buildPromt() {
    return '''
Bạn là một người bạn thân thiện đang giúp người dùng trả lời tin nhắn trong cuộc trò chuyện. Hãy hành xử như một người thật:

1. Phân tích ngữ cảnh và cảm xúc trong tin nhắn nhận được
2. Trả lời một cách tự nhiên, như thể bạn đang nhắn tin với bạn bè
3. Giữ phản hồi ngắn gọn (tối đa 2-3 câu), không dài dòng
4. Sử dụng ngôn ngữ gần gũi, thân thiện, phù hợp với văn hóa Việt Nam
5. Thể hiện sự quan tâm, hài hước khi phù hợp
6. Không thêm giải thích hay ghi chú gì khác
7. Có thể thêm từ vựng của giới trẻ khi phù hợp
8. Không dùng emoji
9. Quan trọng: Sử dụng xưng hô phù hợp với đối phương:
   - Nếu họ dùng "mình", bạn cũng dùng "mình"
   - Nếu họ dùng "tôi", bạn cũng dùng "tôi" 
   - Nếu họ dùng "anh", bạn có thể xưng là em và ngược lại 
   - Nếu họ dùng "tao/tao mày", có thể dùng xưng hô tương xứng như vậy hoặc lịch sử tuỳ vào ngữ cảnh
   - Phù hợp với mức độ thân mật trong cuộc trò chuyện
10. Tham chiếu tới các tin nhắn trước đó để đưa ra gợi ý phù hợp nhất
11. Đây là app hẹn hò nên hãy gợi ý liên quan đến chủ đề này có thể nhất

Ví dụ:
- Tin nhắn: "Hôm nay bạn thế nào?"
  Phản hồi: "Mình ổn á, đang làm việc nè"

- Tin nhắn: "Mình buồn quá"
  Phản hồi: "Sao vậy bạn? Kể mình nghe đi, mình lắng nghe mà"

- Tin nhắn: "Đi chơi không?"
  Phản hồi: "Ok đi! Đi đâu đây?"

- Tin nhắn: "Tôi muốn hỏi bạn một việc"
  Phản hồi: "Tôi đang nghe đây, bạn cứ hỏi nhé"
''';
  }

  void _initializeAI() {
    // Tạo prompt hệ thống bằng tiếng Việt
    String systemPrompt = _buildPromt();
    _model = FirebaseAI.vertexAI(location: 'global').generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(systemPrompt),
    );
    _chatSession = _model.startChat();
  }

  Future<void> _getAISuggestion(String receivedMessage) async {
    if (!isAITurnOn) return;

    setState(() {
      isAIThinking = true;
      aiSuggestion = null;
      isAISuggestionVisible = false;
    });

    try {
      final response = await _chatSession.sendMessage(
        Content.text(
          "Tin nhắn từ bạn: '$receivedMessage'\n\nHãy trả lời một cách tự nhiên như đang nhắn tin với bạn bè:",
        ),
      );

      final suggestion = response.text ?? '';
      if (suggestion.isNotEmpty && mounted) {
        setState(() {
          aiSuggestion = suggestion;
          isAIThinking = false;
          isAISuggestionVisible = true;
        });
      } else {
        setState(() {
          isAIThinking = false;
        });
      }
    } catch (e) {
      debugPrint('AI suggestion error: $e');
      setState(() {
        isAIThinking = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAI();
    messageController.addListener(_onMessageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _onMessageChanged() {
    // Hide AI suggestion when user starts typing
    if (messageController.text.isNotEmpty && isAISuggestionVisible) {
      setState(() {
        isAISuggestionVisible = false;
      });
    }
  }

  void _initializeChat() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      setState(() {
        socket = args['socket'];
        isServer = args['isServer'] ?? false;
      });
      _listenToSocket();
    }
  }

  @override
  void dispose() {
    socketSubscription?.cancel();
    socket?.destroy();
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    super.dispose();
  }

  void _listenToSocket() {
    if (socket == null) return;

    socketSubscription = socket!.listen(
      (data) {
        if (mounted) {
          final message = utf8.decode(data);
          setState(() {
            messages.add(isServer ? "Client: $message" : "Server: $message");
          });
          // Get AI suggestion for received message
          _getAISuggestion(message);
        }
      },
      onDone: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Đối phương đã ngắt kết nối")),
          );
          _returnToMainScreen();
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("❌ Lỗi kết nối: $error")));
          _returnToMainScreen();
        }
      },
      cancelOnError: false,
    );
  }

  void _sendMessage() {
    String message = messageController.text.trim();
    if (message.isEmpty || socket == null) return;

    try {
      socket!.write(message);
      if (mounted) {
        setState(() {
          messages.add("Tôi: $message");
          // Clear AI suggestion after sending
          aiSuggestion = null;
          isAISuggestionVisible = false;
        });
      }
      messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Lỗi gửi tin nhắn: $e")));
      }
    }
  }

  void _useAISuggestion() {
    if (aiSuggestion != null && messageController.text.isEmpty) {
      setState(() {
        messageController.text = aiSuggestion!;
        aiSuggestion = null;
        isAISuggestionVisible = false;
      });
    }
  }

  void _returnToMainScreen() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isServer ? 'Chat với Client' : 'Chat với Server'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _returnToMainScreen,
        ),
        actions: [
          Row(
            children: [
              const Text(
                'AI',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Switch(
                value: isAITurnOn,
                onChanged: (value) {
                  setState(() {
                    isAITurnOn = value;
                    if (!value) {
                      aiSuggestion = null;
                      isAISuggestionVisible = false;
                      isAIThinking = false;
                    }
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMyMessage = message.startsWith('Tôi:');

                return Align(
                  alignment: isMyMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isMyMessage ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isMyMessage ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI Thinking/Suggestion
                if (isAITurnOn && (isAIThinking || aiSuggestion != null))
                  AnimatedOpacity(
                    opacity: (isAIThinking || isAISuggestionVisible)
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      height: (isAIThinking || isAISuggestionVisible)
                          ? null
                          : 0,
                      child: InkWell(
                        onTap: isAIThinking ? null : _useAISuggestion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            border: const Border(
                              top: BorderSide(color: Colors.blue, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Thinking indicator or lightbulb icon
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isAIThinking
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.lightbulb,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.5),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: isAIThinking
                                      ? const Text(
                                          'AI đang nghĩ...',
                                          key: ValueKey('thinking'),
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      : Text(
                                          '$aiSuggestion',
                                          key: ValueKey(aiSuggestion),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: null,
                                          softWrap: true,
                                        ),
                                ),
                              ),
                              if (!isAIThinking)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isAISuggestionVisible = false;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Text Input
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
