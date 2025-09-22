import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class StudyStyleStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const StudyStyleStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<StudyStyleStep> createState() => _StudyStyleStepState();
}

class _StudyStyleStepState extends State<StudyStyleStep> {
  String? _selectedStudyStyle;

  @override
  void initState() {
    super.initState();
    _selectedStudyStyle = widget.profileData.studyStyle;
  }

  bool get _isFormValid => _selectedStudyStyle != null;

  void _saveAndNext() {
    if (_isFormValid) {
      widget.profileData.studyStyle = _selectedStudyStyle;
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.onPrimary,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your study style',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),

            // Study Style Options
            ...studyStyles.map((style) {
              final isSelected = _selectedStudyStyle == style.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStudyStyle = style.name;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary
                          : context.colors.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? context.primary : context.outline,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: context.primary.withValues(alpha: .3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? context.colors.onPrimary
                                : context.onSurface,
                          ),
                        ),
                        if (style.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            style.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? context.colors.onPrimary.withValues(
                                      alpha: .9,
                                    )
                                  : context.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '3/10',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid ? _saveAndNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: context.outline,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
