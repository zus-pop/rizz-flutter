import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/pages/auth/phone_verification_page.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/profile_setup_page.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_phoneFocusNode.hasFocus) {
      // Scroll to the phone input field when it gains focus
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          200.0, // Approximate position of the phone input field
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _loginWithPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Nhập số điện thoại của bạn');
      return;
    }

    if (_phoneController.text.trim().length < 10) {
      _showSnackBar('Hãy nhập số điện thoại hợp lệ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PhoneVerificationPage(phoneNumber: _phoneController.text.trim()),
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );
    final success = await authProvider.loginWithGoogle();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Check if profile setup is complete
        // await authProvider.updateProfileSetupStatus();

        if (mounted) {
          if (authProvider.isProfileSetupComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomTabPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
            );
          }
        }
      } else {
        _showSnackBar('Lỗi đăng nhập Google. Vui lòng thử lại');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      // Logo or App Name
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: context.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.asset(
                            'assets/images/appicon.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Chào mừng!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để bắt đầu khám phá các giọng nói của mọi người',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.colors.onSurface.withValues(alpha: .6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Phone Number Input (commented out)
                      // ... existing commented code ...
                      const SizedBox(height: 24),

                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          icon: Icon(
                            Icons.g_mobiledata,
                            color: context.primary,
                            size: 50,
                          ),
                          label: Text(
                            'Tiếp tục với Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colors.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Add some space before bottom content
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),

              // Terms and Privacy at bottom (outside scroll view)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: .6),
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Bằng cách tiếp tục, bạn đồng ý với ',
                      ),
                      TextSpan(
                        text: 'Điều khoản dịch vụ',
                        style: TextStyle(color: context.primary),
                      ),
                      const TextSpan(text: ' và '),
                      TextSpan(
                        text: 'Chính sách bảo mật',
                        style: TextStyle(color: context.primary),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
