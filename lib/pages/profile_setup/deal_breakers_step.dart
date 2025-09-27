import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class DealBreakersStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const DealBreakersStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<DealBreakersStep> createState() => _DealBreakersStepState();
}

class _DealBreakersStepState extends State<DealBreakersStep> {
  Set<String> _selectedDealBreakers = <String>{};

  bool get _isFormValid => _selectedDealBreakers.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedDealBreakers = Set.from(widget.profileData.dealBreakers);
  }

  void _saveAndNext() {
    widget.profileData.dealBreakers = _selectedDealBreakers.toList();
    widget.onNext();
  }

  void _toggleDealBreaker(String dealBreakerName) {
    setState(() {
      if (_selectedDealBreakers.contains(dealBreakerName)) {
        _selectedDealBreakers.remove(dealBreakerName);
      } else {
        _selectedDealBreakers.add(dealBreakerName);
      }
    });
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
            const Text(
              'Your deal breakers',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional. Tap to select what you absolutely',
              style: TextStyle(
                fontSize: 16,
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),

            // Deal Breakers Options
            Expanded(
              child: ListView.builder(
                itemCount: dealBreakers.length,
                itemBuilder: (context, index) {
                  final dealBreaker = dealBreakers[index];
                  final isSelected = _selectedDealBreakers.contains(
                    dealBreaker.name,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => _toggleDealBreaker(dealBreaker.name),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.primary
                              : context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? context.primary
                                : context.outline,
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
                          dealBreaker.name,
                          style: TextStyle(
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
                },
              ),
            ),

            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '9/10',
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
