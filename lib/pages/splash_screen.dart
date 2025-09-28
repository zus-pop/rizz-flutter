import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/pages/onboarding_screen.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/auth/login_page.dart';
import 'package:rizz_mobile/pages/profile_setup_page.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay
    
    if (!mounted) return;
    
    // Initialize authentication provider
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    await authProvider.initializeAuth();
    
    if (!mounted) return;
    
    // Check if user is logged in and profile setup is complete
    if (authProvider.isLoggedIn && authProvider.isProfileSetupComplete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomTabPage()),
      );
      return;
    }

    // If logged in but profile setup not complete
    if (authProvider.isLoggedIn && !authProvider.isProfileSetupComplete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
      );
      return;
    }

    // Check onboarding status for not logged in users
    final bool onboardingComplete = await OnboardingService.isOnboardingComplete();
    
    if (!mounted) return;
    
    if (onboardingComplete) {
      // Show login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // Show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade400,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.favorite,
                size: 60,
                color: Colors.pink.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rizz',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find your perfect match',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}