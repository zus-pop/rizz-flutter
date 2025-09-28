import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/profile_setup_page.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationPage({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  String _currentOtp = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          }
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  Future<void> _verifyOTP() async {
    if (_currentOtp.length != 6) {
      _showSnackBar('Please enter the complete OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    final success = await authProvider.loginWithPhone(widget.phoneNumber, _currentOtp);

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
        _showSnackBar('Invalid OTP. Please try again.');
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isResending = true;
    });

    // Simulate resend OTP
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isResending = false;
        _resendTimer = 60;
      });
      _startResendTimer();
      _showSnackBar('OTP sent successfully!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('Invalid') 
            ? Colors.red.shade400 
            : Colors.green.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              
              // Icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.sms,
                  size: 50,
                  color: Colors.pink.shade400,
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Verify Your Phone',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Enter the 6-digit code sent to',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // PIN Code Fields
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _pinController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: Colors.pink.shade50,
                  inactiveFillColor: Colors.grey.shade100,
                  selectedFillColor: Colors.pink.shade100,
                  activeColor: Colors.pink.shade400,
                  inactiveColor: Colors.grey.shade300,
                  selectedColor: Colors.pink.shade400,
                ),
                animationDuration: const Duration(milliseconds: 300),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,
                onChanged: (value) {
                  setState(() {
                    _currentOtp = value;
                  });
                },
                onCompleted: (value) {
                  _verifyOTP();
                },
              ),
              
              const SizedBox(height: 32),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: _resendTimer > 0 || _isResending ? null : _resendOTP,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _resendTimer > 0 ? 'Resend in ${_resendTimer}s' : 'Resend',
                            style: TextStyle(
                              color: _resendTimer > 0 
                                  ? Colors.grey 
                                  : Colors.pink.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Help Text
              Text(
                'Enter the verification code to continue',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}