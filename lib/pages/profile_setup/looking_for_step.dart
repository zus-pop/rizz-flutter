import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class LookingForStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const LookingForStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<LookingForStep> createState() => _LookingForStepState();
}

class _LookingForStepState extends State<LookingForStep> {
  String? _selectedLookingFor;

  @override
  void initState() {
    super.initState();
    _selectedLookingFor = widget.profileData.lookingFor;
  }

  bool get _isFormValid => _selectedLookingFor != null;

  void _saveAndNext() {
    if (_isFormValid) {
      widget.profileData.lookingFor = _selectedLookingFor;
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Looking for',
              style: AppTheme.headline2.copyWith(color: context.onSurface),
            ),
            const SizedBox(height: 40),

            // Looking For Options
            ...lookingForOptions.map((option) {
              final isSelected = _selectedLookingFor == option.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLookingFor = option.name;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? context.primary : context.outline,
                        width: isSelected ? 2 : 1,
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
                    child: Text(
                      option.name,
                      style: AppTheme.body1.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? context.colors.onPrimary
                            : context.onSurface,
                      ),
                      textAlign: TextAlign.center,
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
                  '2/10',
                  style: AppTheme.caption.copyWith(
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
                    Text(
                      'Next',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
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

