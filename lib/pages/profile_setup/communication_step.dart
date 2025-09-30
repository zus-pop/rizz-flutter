import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class CommunicationStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const CommunicationStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<CommunicationStep> createState() => _CommunicationStepState();
}

class _CommunicationStepState extends State<CommunicationStep> {
  String? _selectedCommunication;

  @override
  void initState() {
    super.initState();
    _selectedCommunication = widget.profileData.communicationPreference;
  }

  bool get _isFormValid => _selectedCommunication != null;

  void _saveAndNext() {
    if (_isFormValid) {
      widget.profileData.communicationPreference = _selectedCommunication;
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
              'Bạn thích',
              style: AppTheme.headline2.copyWith(color: context.onSurface),
            ),
            const SizedBox(height: 20),

            // Communication Options
            ...communicationPreferences.map((comm) {
              final isSelected = _selectedCommunication == comm.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCommunication = comm.name;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comm.name,
                          style: AppTheme.body1.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? context.colors.onPrimary
                                : context.onSurface,
                          ),
                        ),
                        if (comm.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            comm.description!,
                            style: AppTheme.caption.copyWith(
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
                  '8/10',
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
