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
      _showSnackBar('Please enter your phone number');
      return;
    }

    if (_phoneController.text.trim().length < 10) {
      _showSnackBar('Please enter a valid phone number');
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
        await authProvider.updateProfileSetupStatus();

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
        _showSnackBar('Failed to sign in with Google. Please try again.');
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
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your dating journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.onSurface.withValues(alpha: .6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Phone Number Input
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(
                        Icons.phone,
                        color: context.colors.onSurface.withValues(alpha: .6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Continue with Phone Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: context.colors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Continue with Phone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: context.colors.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(alpha: .6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.colors.outline)),
                  ],
                ),

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
                      'Continue with Google',
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

                const SizedBox(height: 48),

                // Terms and Privacy
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: .6),
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(color: context.primary),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: context.primary),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
