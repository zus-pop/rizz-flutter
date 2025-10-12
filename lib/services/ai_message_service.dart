import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class AIMessageService {
  late final GenerativeModel _model;

  AIMessageService() {
    _initializeAI();
  }

  void _initializeAI() {
    final jsonSchema = Schema.object(
      properties: {
        'suggestions': Schema.array(
          items: Schema.string(
            description:
                'Một gợi ý tin nhắn hấp dẫn, vui nhộn và phù hợp với tình huống trò chuyện',
          ),
        ),
        'context': Schema.string(
          description: 'Ngữ cảnh hoặc chủ đề của các gợi ý tin nhắn',
        ),
      },
    );

    _model = FirebaseAI.vertexAI(location: 'global').generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: jsonSchema,
      ),
    );
  }

  /// Generate message suggestions based on conversation context
  Future<Map<String, dynamic>?> generateMessageSuggestions({
    required List<Map<String, dynamic>> recentMessages,
    required String otherUserName,
    String? otherUserBio,
    List<String>? otherUserInterests,
    int maxSuggestions = 3,
  }) async {
    try {
      debugPrint('🤖 Generating AI message suggestions...');

      // Build conversation context
      final conversationContext = _buildConversationContext(
        recentMessages: recentMessages,
        otherUserName: otherUserName,
        otherUserBio: otherUserBio,
        otherUserInterests: otherUserInterests,
      );

      final prompt =
          '''
Dựa trên ngữ cảnh cuộc trò chuyện sau, hãy tạo $maxSuggestions gợi ý tin nhắn hấp dẫn, vui nhộn và phù hợp.

YÊU CẦU:
- Tin nhắn phải tự nhiên, thân thiện và thu hút
- Sử dụng ngôn ngữ tiếng Việt phù hợp với giới trẻ
- Tránh các câu hỏi quá xâm phạm hoặc nhạy cảm
- Tập trung vào việc tạo sự kết nối và tương tác tích cực
- Mỗi gợi ý nên dưới 100 ký tự
- Phù hợp với phong cách trò chuyện hiện tại

NGỮ CẢNH CUỘC TRÒ CHUYỆN:
$conversationContext

Hãy trả về JSON với format:
{
  "suggestions": ["Gợi ý 1", "Gợi ý 2", "Gợi ý 3"],
  "context": "Mô tả ngắn về chủ đề cuộc trò chuyện"
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      debugPrint('🤖 AI Response: ${response.text}');

      if (response.text != null) {
        final jsonResponse = jsonDecode(response.text!);
        return jsonResponse;
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('❌ Error generating AI suggestions: $e');
      return null;
    }
  }

  /// Build conversation context from recent messages
  String _buildConversationContext({
    required List<Map<String, dynamic>> recentMessages,
    required String otherUserName,
    String? otherUserBio,
    List<String>? otherUserInterests,
  }) {
    final buffer = StringBuffer();

    // Add user info
    buffer.writeln('Đối phương: $otherUserName');
    if (otherUserBio != null && otherUserBio.isNotEmpty) {
      buffer.writeln('Thông tin về $otherUserName: $otherUserBio');
    }
    if (otherUserInterests != null && otherUserInterests.isNotEmpty) {
      buffer.writeln('Sở thích: ${otherUserInterests.join(", ")}');
    }

    buffer.writeln('\nLịch sử tin nhắn gần đây (tối đa 10 tin):');

    // Add recent messages (limit to last 10)
    final messagesToShow = recentMessages.take(10);
    for (final message in messagesToShow) {
      final sender = message['isMe'] == true ? 'Bạn' : otherUserName;
      final text = message['text'] ?? '';
      buffer.writeln('$sender: $text');
    }

    // Add conversation analysis
    final lastMessage = recentMessages.isNotEmpty ? recentMessages.last : null;
    if (lastMessage != null) {
      final isLastMessageFromMe = lastMessage['isMe'] == true;
      if (isLastMessageFromMe) {
        buffer.writeln('\nTình huống: Đang chờ phản hồi từ $otherUserName');
      } else {
        buffer.writeln(
          '\nTình huống: Vừa nhận tin nhắn từ $otherUserName, cần trả lời',
        );
      }
    } else {
      buffer.writeln('\nTình huống: Bắt đầu cuộc trò chuyện mới');
    }

    return buffer.toString();
  }

  /// Get predefined fallback suggestions for when AI fails
  List<String> getFallbackSuggestions(String otherUserName) {
    return [
      'Chào $otherUserName! Rất vui được làm quen 😊',
      'Bạn đang làm gì vậy? Kể nghe với đi!',
      'Hôm nay của bạn thế nào? Có kế hoạch gì thú vị không?',
      'Chúng ta có điểm chung gì không nhỉ? 😄',
    ];
  }
}
