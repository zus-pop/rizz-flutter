import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';

class FilterModal extends StatefulWidget {
  final RangeValues initialAgeRange;
  final double initialDistance;
  final String? initialEmotion;
  final String? initialVoiceQuality;
  final String? initialAccent;
  final String? initialGender;
  final String? initialUniversity;
  final List<String>? initialInterests;
  final Function(
    RangeValues ageRange,
    double distance,
    String? emotion,
    String? voiceQuality,
    String? accent,
    String? gender,
    String? university,
    List<String>? interests,
  )
  onApplyFilter;

  const FilterModal({
    super.key,
    required this.initialAgeRange,
    required this.initialDistance,
    this.initialEmotion,
    this.initialVoiceQuality,
    this.initialAccent,
    this.initialGender,
    this.initialUniversity,
    this.initialInterests,
    required this.onApplyFilter,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late RangeValues _ageRange;
  late double _distance;
  late String? _selectedEmotion;
  late String? _selectedVoiceQuality;
  late String? _selectedAccent;
  late String? _selectedGender;
  late String? _selectedUniversity;
  late List<String> _selectedInterests;

  // Voice filtering state
  final TextEditingController _voiceFilterController = TextEditingController();
  String _voiceFilterText = '';
  bool _isProcessingVoiceFilter = false;
  bool _isListening = false; // Local state for UI
  stt.SpeechToText? _speech;

  // AI model for voice filter processing
  late GenerativeModel _model;

  final List<String> _genders = ['Nam', 'Nữ'];

  final List<String> _availableInterests = [
    'Nhiếp ảnh',
    'Mua sắm',
    'Karaoke',
    'Yoga',
    'Nấu ăn',
    'Quần vợt',
    'Chạy bộ',
    'Bơi lội',
    'Nghệ thuật',
    'Du lịch',
    'Thể thao mạo hiểm',
    'Âm nhạc',
    'Đồ uống',
    'Trò chơi điện tử',
  ];

  @override
  void initState() {
    _ageRange = widget.initialAgeRange;
    _distance = widget.initialDistance;
    _selectedEmotion = widget.initialEmotion;
    _selectedVoiceQuality = widget.initialVoiceQuality;
    _selectedAccent = widget.initialAccent;
    _selectedGender = widget.initialGender;
    _selectedUniversity = widget.initialUniversity;
    _selectedInterests = widget.initialInterests ?? [];
    _initializeAI();
    _initSpeech();

    super.initState();
  }

  void _initializeAI() {
    final jsonSchema = Schema.object(
      properties: {
        'emotion': Schema.enumString(
          enumValues: [
            "Vui",
            "Buồn",
            "Tự tin",
            "Lo lắng",
            "Trung lập",
            "Ngông",
            "Xấu hổ",
            "Rụt rè",
          ],
          description: 'Cảm xúc từ mô tả giọng nói',
        ),
        'voice_quality': Schema.enumString(
          enumValues: [
            "Ấm",
            "Khàn",
            "Trong trẻo",
            "Sáng",
            "Mượt",
            "Trầm",
            "Ngang mũi",
            "Thì thào",
          ],
          description: 'Chất lượng giọng nói từ mô tả',
        ),
        'accent': Schema.enumString(
          enumValues: [
            "Tây Bắc Bộ",
            "Đông Bắc bộ",
            "Đồng bằng sông Hồng",
            "Bắc Trung Bộ",
            "Nam Trung Bộ",
            "Tây Nguyên",
            "Đông Nam Bộ",
            "Miền Tây",
            "Không xác định",
          ],
          description: 'Vùng miền từ mô tả giọng nói',
        ),
      },
      optionalProperties: ['emotion', 'voice_quality', 'accent'],
    );

    _model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(
        'Bỏ qua những field không thể phân tích, đừng cố đưa nó vào response',
      ),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: jsonSchema,
      ),
    );
  }

  void _onVoiceFilterChanged(String text) {
    setState(() {
      _voiceFilterText = text;
    });
  }

  Future<void> _processVoiceFilterFromInput() async {
    if (_voiceFilterText.trim().isEmpty) return;
    await _processVoiceFilter(_voiceFilterText.trim());
  }

  void _toggleListening() {
    if (_speech == null) return;
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _stopListening() {
    if (_speech == null) return;
    _speech!.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    final available = await _speech!.initialize(
      onError: (e) => debugPrint('STT error: ${e.errorMsg}'),
      onStatus: (status) {
        debugPrint('STT status: $status');
        // Update listening state based on status
        setState(() {
          _isListening = status == 'listening';
        });
      },
    );
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể khởi tạo nhận diện giọng nói')),
      );
    }
  }

  void _startListening() async {
    if (_speech == null) return;
    final hasSpeech = await _speech!.hasPermission;
    if (!hasSpeech) {
      final available = await _speech!.initialize();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thiếu quyền microphone')),
          );
        }
        return;
      }
    }

    setState(() {
      _isListening = true;
      _voiceFilterController.text = ''; // Clear previous text
      _voiceFilterText = '';
    });

    await _speech!.listen(
      localeId: 'vi_VN',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      pauseFor: const Duration(
        seconds: 3,
      ), // Auto-stop after 3 seconds of silence
      listenFor: const Duration(seconds: 30), // Maximum listen duration
      onResult: (result) {
        setState(() {
          _voiceFilterController.text = result.recognizedWords;
          _voiceFilterText = result.recognizedWords;

          // If final result (user stopped speaking), auto-stop and process
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _stopListening();
            // Auto-process after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _voiceFilterText.trim().isNotEmpty) {
                _processVoiceFilterFromInput();
              }
            });
          }
        });
      },
      onSoundLevelChange: (level) {
        // Optional: Handle sound level changes for visual feedback
      },
    );
  }

  Future<void> _processVoiceFilter(String text) async {
    debugPrint(text);

    setState(() {
      _isProcessingVoiceFilter = true;
    });

    // Show the AI thinking modal
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => _aIThinkingModal(),
      );
    }

    try {
      final prompt = text;
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        final jsonResponse = jsonDecode(response.text!);

        // Close the thinking modal
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        setState(() {
          _selectedEmotion = jsonResponse['emotion'];
          _selectedVoiceQuality = jsonResponse['voice_quality'];
          _selectedAccent = jsonResponse['accent'];
        });
        debugPrint('JSON: $jsonResponse');

        // Show success animation briefly
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => _aISuccessModal(
              emotion: jsonResponse['emotion'],
              voiceQuality: jsonResponse['voice_quality'],
              accent: jsonResponse['accent'],
            ),
          );
        }

        // Auto-apply filters and close the bottom sheet
        widget.onApplyFilter(
          _ageRange,
          _distance,
          _selectedEmotion,
          _selectedVoiceQuality,
          _selectedAccent,
          _selectedGender,
          _selectedUniversity,
          _selectedInterests,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error processing voice filter: $e');
      // Close the thinking modal if it's still open
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý giọng nói: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessingVoiceFilter = false;
      });
    }
  }

  @override
  void dispose() {
    _voiceFilterController.dispose();
    super.dispose();
  }

  Widget _buildModernExampleChip(String text, BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _voiceFilterController.text = text;
          _voiceFilterText = text;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_high_rounded,
              size: 12,
              color: context.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: context.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aIThinkingModal() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated AI icon
            _PulsingAIIcon(),
            const SizedBox(height: 24),

            // Title with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [context.primary, context.colors.secondary],
              ).createShader(bounds),
              child: const Text(
                'AI đang suy nghĩ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Animated dots (ChatGPT style)
            _ThinkingDots(),
            const SizedBox(height: 20),

            // Status text
            Text(
              'Đang phân tích giọng nói của bạn...',
              style: TextStyle(
                fontSize: 14,
                color: context.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _aISuccessModal({
    String? emotion,
    String? voiceQuality,
    String? accent,
  }) {
    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primary.withValues(alpha: 0.95),
              context.colors.secondary.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Phân tích thành công!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Results preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (emotion != null)
                    _resultRow(Icons.mood_rounded, 'Cảm xúc', emotion),
                  if (voiceQuality != null) ...[
                    const SizedBox(height: 8),
                    _resultRow(
                      Icons.graphic_eq_rounded,
                      'Chất giọng',
                      voiceQuality,
                    ),
                  ],
                  if (accent != null) ...[
                    const SizedBox(height: 8),
                    _resultRow(Icons.location_on_rounded, 'Vùng miền', accent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bộ lọc',
                  style: AppTheme.headline3.copyWith(color: context.primary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: context.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                if (!profileProvider.isFilteringEnabled) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: context.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bộ lọc đã tắt',
                          style: AppTheme.headline4.copyWith(
                            color: context.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bật bộ lọc để tùy chỉnh kết quả tìm kiếm',
                          style: AppTheme.body1.copyWith(
                            color: context.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Voice Analysis Filter (Natural Language) - REDESIGNED
                      const SizedBox(height: 10),

                      // Modern AI Filter Card with glassmorphism effect
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.primary.withValues(alpha: 0.08),
                              context.colors.secondary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: context.primary.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sleek Header
                              Row(
                                children: [
                                  // Animated gradient icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          context.primary,
                                          context.colors.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: context.primary.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            ShaderMask(
                                              shaderCallback: (bounds) =>
                                                  LinearGradient(
                                                    colors: [
                                                      context.primary,
                                                      context.colors.secondary,
                                                    ],
                                                  ).createShader(bounds),
                                              child: Text(
                                                'AI Voice Filter',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.stars_rounded,
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'AI',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Powered by AI',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.onSurface.withValues(
                                              alpha: 0.6,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Modern text input
                              Container(
                                decoration: BoxDecoration(
                                  color: context.colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isListening
                                        ? context.colors.error.withValues(
                                            alpha: 0.5,
                                          )
                                        : context.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                    width: 1.5,
                                  ),
                                  boxShadow: _isListening
                                      ? [
                                          BoxShadow(
                                            color: context.colors.error
                                                .withValues(alpha: 0.15),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: context.colors.shadow
                                                .withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _voiceFilterController,
                                      onChanged: _onVoiceFilterChanged,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        filled: false,
                                        hintText: _isListening
                                            ? '🎤 Đang lắng nghe...'
                                            : '✨ Mô tả giọng nói bạn muốn tìm...',
                                        hintStyle: TextStyle(
                                          color: context.onSurface.withValues(
                                            alpha: 0.45,
                                          ),
                                          fontSize: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.onSurface,
                                        height: 1.5,
                                      ),
                                    ),

                                    // Listening indicator
                                    if (_isListening)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.colors.error
                                              .withValues(alpha: 0.08),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: context.colors.error,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Đang nghe... (tự động dừng sau 3s im lặng)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: context.colors.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Action buttons - Modern redesign
                              Row(
                                children: [
                                  // Voice button
                                  Expanded(
                                    child: _isListening
                                        ? Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: context.colors.error,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: context.colors.error
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: _toggleListening,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.stop_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Dừng lại',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: context.colors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: context.primary
                                                    .withValues(alpha: 0.2),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: _toggleListening,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.mic_none_rounded,
                                                        color: context.primary,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Nói',
                                                        style: TextStyle(
                                                          color:
                                                              context.primary,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  // AI Process button
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: _isProcessingVoiceFilter
                                            ? LinearGradient(
                                                colors: [
                                                  context.onSurface.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  context.onSurface.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                ],
                                              )
                                            : _voiceFilterText.trim().isEmpty
                                            ? LinearGradient(
                                                colors: [
                                                  context.onSurface.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                  context.onSurface.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                ],
                                              )
                                            : LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  context.primary,
                                                  context.colors.secondary,
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow:
                                            _isProcessingVoiceFilter ||
                                                _voiceFilterText.trim().isEmpty
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: context.primary
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap:
                                              _isProcessingVoiceFilter ||
                                                  _voiceFilterText
                                                      .trim()
                                                      .isEmpty
                                              ? null
                                              : _processVoiceFilterFromInput,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Center(
                                            child: _isProcessingVoiceFilter
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Đang xử lý...',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .auto_awesome_rounded,
                                                        color:
                                                            _voiceFilterText
                                                                .trim()
                                                                .isEmpty
                                                            ? context.onSurface
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  )
                                                            : Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'AI Phân tích',
                                                        style: TextStyle(
                                                          color:
                                                              _voiceFilterText
                                                                  .trim()
                                                                  .isEmpty
                                                              ? context
                                                                    .onSurface
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    )
                                                              : Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Quick suggestions
                              if (!_isProcessingVoiceFilter &&
                                  !_isListening) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'Thử ngay:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _buildModernExampleChip(
                                      'Giọng miền Nam, vui vẻ',
                                      context,
                                    ),
                                    _buildModernExampleChip(
                                      'Giọng ấm, trầm',
                                      context,
                                    ),
                                    _buildModernExampleChip(
                                      'Giọng Bắc, tự tin',
                                      context,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Age Range Filter
                      const SizedBox(height: 40),
                      Text(
                        'Độ tuổi',
                        style: AppTheme.headline4.copyWith(
                          color: context.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_ageRange.start.round()} - ${_ageRange.end.round()} tuổi',
                        style: AppTheme.body1.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: context.primary,
                          inactiveTrackColor: context.onSurface.withValues(
                            alpha: 0.3,
                          ),
                          thumbColor: context.primary,
                          overlayColor: context.primary.withValues(alpha: 0.2),
                          valueIndicatorColor: context.primary,
                          valueIndicatorTextStyle: AppTheme.caption.copyWith(
                            color: context.colors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: RangeSlider(
                          values: _ageRange,
                          min: 18,
                          max: 30,
                          divisions: 47,
                          labels: RangeLabels(
                            _ageRange.start.round().toString(),
                            _ageRange.end.round().toString(),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _ageRange = values;
                            });
                          },
                        ),
                      ),

                      // Premium Filters Section
                      Consumer<AuthenticationProvider>(
                        builder: (context, authProvider, child) {
                          final isPremium = authProvider.isRizzPlus;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Premium section header
                              Row(
                                children: [
                                  Text(
                                    'Bộ lọc nâng cao',
                                    style: AppTheme.headline4.copyWith(
                                      color: context.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.workspace_premium,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Premium upgrade notice
                              if (!isPremium) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.withValues(alpha: 0.1),
                                        Colors.orange.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: Colors.amber,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nâng cấp Premium',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mở khóa bộ lọc theo giới tính, trường đại học và sở thích',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.onSurface.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final status =
                                              await RevenueCatUI.presentPaywallIfNeeded(
                                                "premium",
                                                displayCloseButton: true,
                                              );
                                          if (status ==
                                              PaywallResult.purchased) {
                                            authProvider.isRizzPlus = true;
                                          } else if (status ==
                                              PaywallResult.restored) {
                                            debugPrint("Restored");
                                          } else {
                                            debugPrint("No purchased occur");
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Nâng cấp ngay'),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Gender Filter
                                Text(
                                  'Giới tính',
                                  style: AppTheme.headline4.copyWith(
                                    color: context.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.outline.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _selectedGender,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    hint: Text(
                                      'Chọn giới tính',
                                      style: AppTheme.body1.copyWith(
                                        color: context.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          'Bất kỳ giới tính nào',
                                          style: AppTheme.body1.copyWith(
                                            color: context.onSurface,
                                          ),
                                        ),
                                      ),
                                      ..._genders.map(
                                        (gender) => DropdownMenuItem<String>(
                                          value: gender,
                                          child: Text(
                                            gender,
                                            style: AppTheme.body1.copyWith(
                                              color: context.onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // University Filter
                                Text(
                                  'Trường đại học',
                                  style: AppTheme.headline4.copyWith(
                                    color: context.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.outline.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: TextField(
                                    onChanged: (value) {
                                      _selectedUniversity = value.isEmpty
                                          ? null
                                          : value;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Nhập tên trường đại học',
                                      border: InputBorder.none,
                                      hintStyle: AppTheme.body1.copyWith(
                                        color: context.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    style: AppTheme.body1.copyWith(
                                      color: context.onSurface,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Interests Filter
                                Text(
                                  'Sở thích',
                                  style: AppTheme.headline4.copyWith(
                                    color: context.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _availableInterests.map((interest) {
                                    final isSelected = _selectedInterests
                                        .contains(interest);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedInterests.remove(interest);
                                          } else {
                                            _selectedInterests.add(interest);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? context.primary
                                              : context.colors.surfaceContainer,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? context.primary
                                                : context.outline.withValues(
                                                    alpha: 0.2,
                                                  ),
                                          ),
                                        ),
                                        child: Text(
                                          interest,
                                          style: AppTheme.body2.copyWith(
                                            color: isSelected
                                                ? context.onPrimary
                                                : context.onSurface,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 40),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Fixed Action Buttons at the bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: context.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter toggle
                Consumer<ProfileProvider>(
                  builder: (context, profileProvider, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bật bộ lọc',
                            style: AppTheme.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.onSurface,
                            ),
                          ),
                          Switch(
                            value: profileProvider.isFilteringEnabled,
                            onChanged: (value) {
                              profileProvider.toggleFiltering();
                            },
                            activeThumbColor: context.primary,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    // Reset Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _ageRange = const RangeValues(18, 30);
                            _distance = 50;
                            _selectedEmotion = null;
                            _selectedVoiceQuality = null;
                            _selectedAccent = null;
                            _selectedGender = null;
                            _selectedUniversity = null;
                            _selectedInterests = [];
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Đặt lại',
                          style: AppTheme.body1.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Apply Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApplyFilter(
                            _ageRange,
                            _distance,
                            _selectedEmotion,
                            _selectedVoiceQuality,
                            _selectedAccent,
                            _selectedGender,
                            _selectedUniversity,
                            _selectedInterests,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Áp dụng bộ lọc',
                          style: AppTheme.body1.copyWith(
                            color: context.colors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated AI Icon Widget (pulsing effect)
class _PulsingAIIcon extends StatefulWidget {
  const _PulsingAIIcon();

  @override
  State<_PulsingAIIcon> createState() => _PulsingAIIconState();
}

class _PulsingAIIconState extends State<_PulsingAIIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.primary, context.colors.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Thinking Dots (ChatGPT style)
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final opacity = (math.sin(value * math.pi * 2) + 1) / 2;
            final scale = 0.6 + (opacity * 0.4);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.primary.withValues(alpha: opacity),
                        context.colors.secondary.withValues(alpha: opacity),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
