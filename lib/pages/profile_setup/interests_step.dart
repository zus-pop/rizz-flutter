import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class InterestsStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const InterestsStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  Set<String> _selectedInterests = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedInterests = Set.from(widget.profileData.interests);
  }

  bool get _isFormValid => _selectedInterests.isNotEmpty;

  void _saveAndNext() {
    widget.profileData.interests = _selectedInterests.toList();
    widget.onNext();
  }

  void _toggleInterest(String interestName) {
    setState(() {
      if (_selectedInterests.contains(interestName)) {
        _selectedInterests.remove(interestName);
      } else if (_selectedInterests.length < 5) {
        _selectedInterests.add(interestName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can select up to 5 interests'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
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
              'Your interests',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select at least 3 of your interests and let everyone know what you\'re passionate about.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Selected count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedInterests.length}/5 selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Interests Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: interests.length,
                itemBuilder: (context, index) {
                  final interest = interests[index];
                  final isSelected = _selectedInterests.contains(interest.name);

                  return GestureDetector(
                    onTap: () => _toggleInterest(interest.name),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.primary
                            : context.colors.onPrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? context.primary
                              : Colors.grey.shade300,
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
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconData(interest.iconName),
                              color: isSelected
                                  ? context.colors.onPrimary
                                  : context.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                interest.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? context.colors.onPrimary
                                      : context.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '5/10',
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
                  backgroundColor: context.primary,
                  foregroundColor: context.colors.onPrimary,
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'camera':
        return Icons.camera_alt;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'mic':
        return Icons.mic;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'restaurant':
        return Icons.restaurant;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'directions_run':
        return Icons.directions_run;
      case 'pool':
        return Icons.pool;
      case 'palette':
        return Icons.palette;
      case 'flight':
        return Icons.flight;
      case 'paragliding':
        return Icons.paragliding;
      case 'music_note':
        return Icons.music_note;
      case 'local_bar':
        return Icons.local_bar;
      case 'sports_esports':
        return Icons.sports_esports;
      default:
        return Icons.favorite;
    }
  }
}
