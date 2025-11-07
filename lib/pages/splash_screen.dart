import 'dart:async'; // Để dùng Future.delayed
import 'dart:math'; // MỚI: Để dùng Random cho màu chữ

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:rizz_mobile/pages/auth/login_page.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
// Import các trang và services từ code logic của bạn
import 'package:rizz_mobile/pages/onboarding_screen.dart';
import 'package:rizz_mobile/pages/profile_setup_page.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/services/onboarding_service.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // MỚI: Dùng 2 biến để điều khiển chuỗi animation
  bool _logoVisible = false;
  bool _messageVisible = false;

  // MỚI: Preload Rive animation
  RiveWidgetController? _riveController;
  bool _riveLoaded = false;

  @override
  void initState() {
    super.initState();
    // MỚI: Preload Rive animation first
    _preloadRiveAnimation();
    // Chạy cả animation và logic
    _checkStatusAndAnimate();
  }

  // MỚI: Preload Rive animation to avoid lag
  Future<void> _preloadRiveAnimation() async {
    try {
      final file = await File.asset(
        'assets/animations/confettis.riv',
        riveFactory: Factory.rive,
      );

      // Create a simple controller for the animation
      if (file != null) {
        _riveController = RiveWidgetController(file);
        _riveLoaded = true;
        debugPrint('Rive animation preloaded successfully');
      }
    } catch (e) {
      debugPrint('Failed to preload Rive animation: $e');
      _riveLoaded = false;
    }
  }

  Future<void> _checkStatusAndAnimate() {
    return Future.delayed(const Duration(seconds: 3))
        .then((_) {
          // 2. Kích hoạt animation "pop" cho Logo + Rizz
          setState(() {
            _logoVisible = true;
          });
          // 3. Chờ 2 giây để xem Logo
          return Future.delayed(const Duration(seconds: 3));
        })
        .then((_) {
          // 4. Cross-fade: Mờ Logo đi VÀ "pop" Message lên
          setState(() {
            _logoVisible = false;
            _messageVisible = true;
          });
          // 5. Chờ 3 giây để đọc Message
          return Future.delayed(const Duration(seconds: 3));
        })
        .then((_) {
          // 6. Chạy logic kiểm tra auth (lấy từ code cũ)
          _runAuthLogic();
        });
  }

  // MỚI: Tách logic auth ra riêng
  Future<void> _runAuthLogic() async {
    if (!mounted) return;

    // Initialize authentication provider
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );
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
    final bool onboardingComplete =
        await OnboardingService.isOnboardingComplete();

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

  // ---- MỚI: Thêm lại logic tạo màu chữ ---- //
  final List<Color> _pastelColors = [
    Colors.pink.shade100,
    Colors.purple.shade100,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.yellow.shade100,
    Colors.orange.shade100,
    Colors.red.shade100,
    Colors.cyan.shade100,
  ];
  final Random _random = Random();
  TextSpan _buildColoredText(String text) {
    List<TextSpan> spans = [];
    const String targetWord = "Rizz";
    Color rizzColor = context.primary; // Màu hồng đậm hơn cho chữ "Rizz"

    int i = 0;
    while (i < text.length) {
      if (text.length >= i + targetWord.length &&
          text.substring(i, i + targetWord.length) == targetWord) {
        spans.add(
          TextSpan(
            text: targetWord,
            style: TextStyle(color: rizzColor),
          ),
        );
        i += targetWord.length;
      } else {
        Color charColor = _pastelColors[_random.nextInt(_pastelColors.length)];
        spans.add(
          TextSpan(
            text: text[i],
            style: TextStyle(color: charColor),
          ),
        );
        i++;
      }
    }
    return TextSpan(children: spans);
  }
  // ---------------------------------------- //

  @override
  Widget build(BuildContext context) {
    const String welcomeMessage =
        'Rizz chúc bạn một ngày 20/10 thật rực rỡ và đầy yêu thương';

    return Scaffold(
      body: Container(
        // Giữ Gradient từ màn hình 20/10
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade50.withValues(
                alpha: 0.8,
              ), // Hồng nhạt (Pastel Pink)
              Colors.white, // Màu trắng ngà
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Giữ Stack và Rive
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Widget 1: Animation Rive - Optimized for performance
            if (_riveLoaded && _riveController != null)
              Opacity(
                opacity: 0.6, // Reduced opacity for better performance
                child: RiveWidget(
                  controller: _riveController!,
                  fit: Fit.contain, // Changed from BoxFit to Fit
                  alignment: Alignment.center,
                ),
              )
            else
              // Fallback: Simple gradient animation while Rive loads
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.pink.shade100.withValues(alpha: 0.3),
                      Colors.white,
                    ],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                ),
              ),

            // Widget 2: Logo + Rizz (Pop IN/OUT)
            AnimatedScale(
              scale: _logoVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                // Mờ vào và mờ ra
                opacity: _logoVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/appicon.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Rizz',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: context.primary,
                      ),
                    ),
                    // ĐÃ XOÁ: "Tìm nửa kia..."
                  ],
                ),
              ),
            ),

            // Widget 3: Lời chúc 20/10 (Pop IN)
            AnimatedScale(
              scale: _messageVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _messageVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      // Style gốc cho RichText
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1.5,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.black38,
                            offset: Offset(1.2, 1.2),
                          ),
                        ],
                      ),
                      children: [
                        // Dùng hàm tạo màu
                        _buildColoredText(welcomeMessage),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // MỚI: Clean up Rive resources
    _riveController?.dispose();
    super.dispose();
  }
}
