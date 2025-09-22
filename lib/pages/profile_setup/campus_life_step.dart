import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class CampusLifeStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const CampusLifeStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<CampusLifeStep> createState() => _CampusLifeStepState();
}

class _CampusLifeStepState extends State<CampusLifeStep> {
  String? _selectedCampusLife;

  @override
  void initState() {
    super.initState();
    _selectedCampusLife = widget.profileData.campusLife;
  }

  bool get _isFormValid => _selectedCampusLife != null;

  void _saveAndNext() {
    if (_isFormValid) {
      widget.profileData.campusLife = _selectedCampusLife;
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your campus life',
              style: AppTheme.headline2.copyWith(color: context.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Give the members',
              style: AppTheme.body1.copyWith(
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),

            // Campus Life Options
            ...campusLife.map((life) {
              final isSelected = _selectedCampusLife == life.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCampusLife = life.name;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? context.primary : context.outline,
                        width: 1,
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
                      life.name,
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
                  '6/10',
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
