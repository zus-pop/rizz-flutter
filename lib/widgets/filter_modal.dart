import 'dart:convert';
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
  bool _isListening = false;
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
          enumValues: ["Ấm", "Khàn", "Trong", "Sáng", "Mượt"],
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
      _speech!.stop();
      setState(() {
        _isListening = false;
      });
      // On stop, if we captured transcript, process it
      if (_voiceFilterController.text.trim().isNotEmpty) {
        _processVoiceFilterFromInput();
      }
    } else {
      _startListening();
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    final available = await _speech!.initialize(
      onError: (e) => debugPrint('STT error: ${e.errorMsg}'),
      onStatus: (status) => debugPrint('STT status: $status'),
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
    });
    await _speech!.listen(
      localeId: 'vi_VN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        setState(() {
          if (result.finalResult) {
            _voiceFilterController.text = result.recognizedWords;
            _voiceFilterText = result.recognizedWords;
          }
        });
      },
    );
  }

  Future<void> _processVoiceFilter(String text) async {
    debugPrint(text);

    setState(() {
      _isProcessingVoiceFilter = true;
    });

    try {
      final prompt = text;
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        final jsonResponse = jsonDecode(response.text!);
        setState(() {
          _selectedEmotion = jsonResponse['emotion'];
          _selectedVoiceQuality = jsonResponse['voice_quality'];
          _selectedAccent = jsonResponse['accent'];
        });
        debugPrint('JSON: $jsonResponse');

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
                      // Age Range Filter
                      const SizedBox(height: 20),
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

                      // Voice Analysis Filter (Natural Language)
                      const SizedBox(height: 40),
                      Text(
                        'Bộ lọc giọng nói thông minh',
                        style: AppTheme.headline4.copyWith(
                          color: context.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mô tả bằng giọng nói loại giọng bạn muốn tìm',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Voice input container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Voice filter text input
                            TextField(
                              controller: _voiceFilterController,
                              onChanged: _onVoiceFilterChanged,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    'Ví dụ: "Tôi muốn tìm giọng nói vui vẻ, ấm áp, có giọng miền Nam"',
                                hintStyle: TextStyle(
                                  color: context.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.outline.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.outline.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: context.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Button row for speech and text processing
                            Row(
                              children: [
                                // Speech-to-text button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _toggleListening,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isListening
                                          ? Colors.red
                                          : context.outline,
                                      foregroundColor: _isListening
                                          ? Colors.white
                                          : context.onSurface,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: Icon(
                                      _isListening ? Icons.stop : Icons.mic,
                                    ),
                                    label: Text(
                                      _isListening ? 'Dừng' : 'Nói',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Process button
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessingVoiceFilter
                                        ? null
                                        : _processVoiceFilterFromInput,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.primary,
                                      foregroundColor: context.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: _isProcessingVoiceFilter
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    context.onPrimary,
                                                  ),
                                            ),
                                          )
                                        : const Icon(Icons.psychology),
                                    label: Text(
                                      _isProcessingVoiceFilter
                                          ? 'Đang phân tích...'
                                          : 'Phân tích bằng AI',
                                      style: const TextStyle(
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

                      const SizedBox(height: 40),

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
                            activeColor: context.primary,
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
                            _ageRange = const RangeValues(18, 65);
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
