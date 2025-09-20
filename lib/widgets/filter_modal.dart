import 'package:flutter/material.dart';

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
      decoration: const BoxDecoration(
        color: Color(0xFF080026), // Secondary color background
        borderRadius: BorderRadius.only(
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
              color: Colors.grey[400],
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFfa5eff),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_ageRange.start.round()} - ${_ageRange.end.round()} years old',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFfa5eff),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xFFfa5eff),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Color(0xFFfa5eff),
                      overlayColor: Color(0xFFfa5eff).withValues(alpha: 0.2),
                      valueIndicatorColor: Color(0xFFfa5eff),
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _distance == 100 ? 'Anywhere' : '${_distance.round()} km',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFfa5eff),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xFFfa5eff),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Color(0xFFfa5eff),
                      overlayColor: Color(0xFFfa5eff).withValues(alpha: 0.2),
                      valueIndicatorColor: Color(0xFFfa5eff),
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
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
                            side: BorderSide(color: Color(0xFFfa5eff)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: Color(0xFFfa5eff),
                              fontSize: 16,
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
                            backgroundColor: Color(0xFFfa5eff),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
