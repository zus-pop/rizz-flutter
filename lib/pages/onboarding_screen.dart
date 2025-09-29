import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/onboarding_item.dart';
import 'package:rizz_mobile/pages/auth/login_page.dart';
import 'package:rizz_mobile/services/onboarding_service.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.completeOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentIndex < onboardingItems.length - 1)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Bỏ qua',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: .6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: onboardingItems.length,
              itemBuilder: (context, index) {
                final item = onboardingItems[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 300,
                        width: 300,
                        decoration: BoxDecoration(
                          color: context.primary.withValues(alpha: .1),
                          border: Border.all(
                            color: context.primary.withValues(alpha: .3),
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getIconForIndex(index),
                          size: 120,
                          color: context.primary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.colors.onSurface,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingItems.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentIndex == index ? 32 : 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? context.primary
                            : context.colors.outline.withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: context.colors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentIndex == onboardingItems.length - 1
                          ? 'Bắt đầu'
                          : 'Tiếp theo',
                      style: const TextStyle(
                        fontSize: 18,
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

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.favorite;
      case 1:
        return Icons.chat_bubble;
      case 2:
        return Icons.people;
      default:
        return Icons.favorite;
    }
  }
}
