import 'package:flutter/material.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class FilterModal extends StatefulWidget {
  final RangeValues initialAgeRange;
  final double initialDistance;
  final Function(RangeValues ageRange, double distance) onApplyFilter;

  const FilterModal({
    super.key,
    required this.initialAgeRange,
    required this.initialDistance,
    required this.onApplyFilter,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late RangeValues _ageRange;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _ageRange = widget.initialAgeRange;
    _distance = widget.initialDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                  'Filters',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age Range Filter
                  const SizedBox(height: 20),
                  Text(
                    'Age Range',
                    style: AppTheme.headline4.copyWith(
                      color: context.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_ageRange.start.round()} - ${_ageRange.end.round()} years old',
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
                  const SizedBox(height: 40),
                  Text(
                    'Maximum Distance',
                    style: AppTheme.headline4.copyWith(
                      color: context.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _distance == 100 ? 'Anywhere' : '${_distance.round()} km',
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
                    child: Slider(
                      value: _distance,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: _distance == 100
                          ? 'Anywhere'
                          : '${_distance.round()} km',
                      onChanged: (double value) {
                        setState(() {
                          _distance = value;
                        });
                      },
                    ),
                  ),

                  const Spacer(),

                  // Action Buttons
                  Row(
                    children: [
                      // Reset Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _ageRange = const RangeValues(18, 65);
                              _distance = 50;
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
                            'Reset',
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
                            widget.onApplyFilter(_ageRange, _distance);
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
                            'Apply Filters',
                            style: AppTheme.body1.copyWith(
                              color: context.colors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
