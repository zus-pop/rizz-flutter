import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';

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
  final primaryColor = const Color(0xFFfa5eff);

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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your campus life',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Give the members',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: primaryColor.withValues(alpha: .3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                      ],
                    ),
                    child: Text(
                      life.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
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
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
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
