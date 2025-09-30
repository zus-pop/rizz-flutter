import 'package:flutter/material.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class FilterModal extends StatefulWidget {
  final RangeValues initialAgeRange;
  final double initialDistance;
  final String? initialEmotion;
  final String? initialVoiceQuality;
  final String? initialAccent;
  final Function(
    RangeValues ageRange,
    double distance,
    String? emotion,
    String? voiceQuality,
    String? accent,
  )
  onApplyFilter;

  const FilterModal({
    super.key,
    required this.initialAgeRange,
    required this.initialDistance,
    this.initialEmotion,
    this.initialVoiceQuality,
    this.initialAccent,
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

  // AI Analysis filter options
  final List<String> _emotions = [
    'Vui',
    'Buồn',
    'Tự tin',
    'Lo lắng',
    'Trung lập',
    'Bố láo',
    'Ngông',
    'Xấu hổ',
    'Rụt rè',
  ];

  final List<String> _voiceQualities = ['Ấm', 'Khàn', 'Trong', 'Sáng', 'Mượt'];

  final List<String> _accents = [
    'Tây Bắc Bộ',
    'Đông Bắc bộ',
    'Đồng bằng sông Hồng',
    'Bắc Trung Bộ',
    'Nam Trung Bộ',
    'Tây Nguyên',
    'Đông Nam Bộ',
    'Miền Tây',
    "Không xác định",
  ];

  @override
  void initState() {
    super.initState();
    _ageRange = widget.initialAgeRange;
    _distance = widget.initialDistance;
    _selectedEmotion = widget.initialEmotion;
    _selectedVoiceQuality = widget.initialVoiceQuality;
    _selectedAccent = widget.initialAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            child: SingleChildScrollView(
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
                      max: 65,
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

                  // Distance Filter
                  // const SizedBox(height: 40),
                  // Text(
                  //   'Maximum Distance',
                  //   style: AppTheme.headline4.copyWith(
                  //     color: context.onSurface,
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   _distance == 100 ? 'Anywhere' : '${_distance.round()} km',
                  //   style: AppTheme.body1.copyWith(
                  //     color: context.primary,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // SliderTheme(
                  //   data: SliderTheme.of(context).copyWith(
                  //     activeTrackColor: context.primary,
                  //     inactiveTrackColor: context.onSurface.withValues(
                  //       alpha: 0.3,
                  //     ),
                  //     thumbColor: context.primary,
                  //     overlayColor: context.primary.withValues(alpha: 0.2),
                  //     valueIndicatorColor: context.primary,
                  //     valueIndicatorTextStyle: AppTheme.caption.copyWith(
                  //       color: context.colors.onPrimary,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  //   child: Slider(
                  //     value: _distance,
                  //     min: 1,
                  //     max: 100,
                  //     divisions: 99,
                  //     label: _distance == 100
                  //         ? 'Anywhere'
                  //         : '${_distance.round()} km',
                  //     onChanged: (double value) {
                  //       setState(() {
                  //         _distance = value;
                  //       });
                  //     },
                  //   ),
                  // ),

                  // // AI Analysis Filters
                  // const SizedBox(height: 40),
                  // Text(
                  //   'Voice Analysis',
                  //   style: AppTheme.headline4.copyWith(
                  //     color: context.onSurface,
                  //   ),
                  // ),
                  // const SizedBox(height: 20),

                  // Emotion Filter
                  Text(
                    'Cảm xúc',
                    style: AppTheme.body1.copyWith(
                      color: context.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedEmotion,
                      hint: Text(
                        'Chọn cảm xúc',
                        style: AppTheme.body1.copyWith(
                          color: context.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'Bất kỳ cảm xúc nào',
                            style: AppTheme.body1.copyWith(
                              color: context.onSurface,
                            ),
                          ),
                        ),
                        ..._emotions.map(
                          (emotion) => DropdownMenuItem<String>(
                            value: emotion,
                            child: Text(
                              emotion,
                              style: AppTheme.body1.copyWith(
                                color: context.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEmotion = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Voice Quality Filter
                  Text(
                    'Chất giọng',
                    style: AppTheme.body1.copyWith(
                      color: context.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedVoiceQuality,
                      hint: Text(
                        'Chọn chất giọng',
                        style: AppTheme.body1.copyWith(
                          color: context.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'Bất kỳ chất giọng nào',
                            style: AppTheme.body1.copyWith(
                              color: context.onSurface,
                            ),
                          ),
                        ),
                        ..._voiceQualities.map(
                          (quality) => DropdownMenuItem<String>(
                            value: quality,
                            child: Text(
                              quality,
                              style: AppTheme.body1.copyWith(
                                color: context.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedVoiceQuality = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Accent Filter
                  Text(
                    'Giọng địa phương',
                    style: AppTheme.body1.copyWith(
                      color: context.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedAccent,
                      hint: Text(
                        'Chọn giọng địa phương',
                        style: AppTheme.body1.copyWith(
                          color: context.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'Bất kỳ giọng địa phương nào',
                            style: AppTheme.body1.copyWith(
                              color: context.onSurface,
                            ),
                          ),
                        ),
                        ..._accents.map(
                          (accent) => DropdownMenuItem<String>(
                            value: accent,
                            child: Text(
                              accent,
                              style: AppTheme.body1.copyWith(
                                color: context.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAccent = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
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
            child: Row(
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
          ),
        ],
      ),
    );
  }
}
