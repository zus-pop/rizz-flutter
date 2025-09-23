import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class ProfileVerificationStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const ProfileVerificationStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<ProfileVerificationStep> createState() =>
      _ProfileVerificationStepState();
}

class _ProfileVerificationStepState extends State<ProfileVerificationStep> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _photoTaken = false;
  File? _capturedImage;

  // Verification states
  bool _isVerifying = false;
  bool _verificationSuccess = false;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        _showError(
          'Camera initialization failed. Please check camera permissions.',
        );
      }
    }
  }

  // Simulate server verification
  Future<void> _verifyPhoto(File photo) async {
    setState(() {
      _isVerifying = true;
    });

    try {
      if (_cameraController!.value.isPreviewPaused) {
        await _cameraController!.resumePreview();
      } else {
        await _cameraController!.pausePreview();
      }
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random success/failure for demo
      // In real implementation, you would send the photo to your server
      final isSuccess = DateTime.now().millisecond % 2 == 0;

      setState(() {
        _isVerifying = false;
        _verificationSuccess = isSuccess;
        if (!isSuccess) {
          _verificationError =
              'Verification failed. Please ensure your face is clearly visible and well-lit.';
        }
      });

      _showVerificationResult();
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _verificationError =
            'Network error. Please check your connection and try again.';
      });
      _showVerificationResult();
    }
  }

  Future<void> _capturePhoto() async {
    if (_photoTaken || _cameraController == null) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      setState(() {
        _capturedImage = imageFile;
        _photoTaken = true;
      });

      widget.profileData.verificationPhoto = imageFile;

      // Start verification process
      await _verifyPhoto(imageFile);
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      _showError('Error capturing photo. Please try again.');
    }
  }

  Future<void> _retakePhoto() async {
    if (_cameraController!.value.isPreviewPaused) {
      await _cameraController!.resumePreview();
    } else {
      await _cameraController!.pausePreview();
    }
    setState(() {
      _photoTaken = false;
      _capturedImage = null;
      _isVerifying = false;
      _verificationSuccess = false;
      _verificationError = null;
    });
  }

  void _showVerificationResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _verificationSuccess
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _verificationSuccess ? Icons.check : Icons.close,
                  color: _verificationSuccess ? Colors.green : Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _verificationSuccess
                    ? 'Verification Successful!'
                    : 'Verification Failed',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _verificationSuccess
                    ? 'Your identity has been verified successfully.'
                    : _verificationError ?? 'Please try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_verificationSuccess) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onNext();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: context.colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _retakePhoto();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: context.colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String get _instructionText {
    if (_photoTaken) {
      if (_isVerifying) return 'Verifying your identity...';
      if (_verificationSuccess) return 'Verification successful!';
      if (_verificationError != null) return 'Verification failed';
      return 'Photo captured successfully!';
    }

    return 'Position your face in the oval and tap to capture';
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top Section - Header and Instructions
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Profile Verification',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a clear selfie for profile verification',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.onSurface.withValues(alpha: .7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isVerifying
                        ? Colors.blue.withValues(alpha: .1)
                        : _verificationSuccess
                        ? Colors.green.withValues(alpha: .1)
                        : _verificationError != null
                        ? Colors.red.withValues(alpha: .1)
                        : context.colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isVerifying
                          ? Colors.blue
                          : _verificationSuccess
                          ? Colors.green
                          : _verificationError != null
                          ? Colors.red
                          : context.outline.withValues(alpha: .3),
                      width: 1,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Text(
                      _instructionText,
                      key: ValueKey<String>(_instructionText),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isVerifying
                            ? Colors.blue
                            : _verificationSuccess
                            ? Colors.green
                            : _verificationError != null
                            ? Colors.red
                            : context.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Camera Section - Expanded to fill remaining space
          Expanded(
            child: Stack(
              children: [
                // Camera Preview
                if (_isInitialized && !_photoTaken)
                  Positioned.fill(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height:
                                MediaQuery.of(context).size.width *
                                _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Captured Photo Preview
                if (_photoTaken && _capturedImage != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height:
                                MediaQuery.of(context).size.width *
                                _cameraController!.value.aspectRatio,
                            child: Image.file(
                              _capturedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Verification Loading Overlay
                if (_isVerifying)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: Colors.black.withValues(alpha: 0.8),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 3,
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.blue,
                                  strokeWidth: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Verifying your identity...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please wait while we verify your photo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Oval Overlay (only show when not verifying)
                if (!_isVerifying)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SimpleOvalOverlayPainter(isCapturing: false),
                    ),
                  ),

                // Loading indicator for camera initialization
                if (!_isInitialized)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: context.primary),
                        const SizedBox(height: 16),
                        const Text(
                          'Initializing camera...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Section - Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: context.colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_photoTaken && !_isVerifying) ...[
                  // Manual Capture Button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.primary.withValues(alpha: .3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera,
                        color: context.colors.onPrimary,
                        size: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to capture',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.onSurface.withValues(alpha: .7),
                    ),
                  ),
                ] else if (_photoTaken &&
                    !_verificationSuccess &&
                    !_isVerifying) ...[
                  // Retake Button (only show if verification failed or not started)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _retakePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.surfaceContainer,
                        foregroundColor: context.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Retake Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Placeholder to maintain height consistency
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.primary.withValues(alpha: .5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.primary.withValues(alpha: .3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera,
                      color: context.colors.onPrimary,
                      size: 50,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleOvalOverlayPainter extends CustomPainter {
  final bool isCapturing;

  SimpleOvalOverlayPainter({required this.isCapturing});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radiusX = 160.0;
    const radiusY = 200.0;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );

    // Create outer path
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create oval path
    final ovalPath = Path()..addOval(ovalRect);

    // Subtract oval from outer to create cutout
    final overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      ovalPath,
    );

    // Draw dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: .7);
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw oval border
    final borderPaint = Paint()
      ..color = isCapturing ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawOval(ovalRect, borderPaint);

    // Draw pulsing effect when capturing
    if (isCapturing) {
      final pulsePaint = Paint()
        ..color = Colors.green.withValues(alpha: .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;

      canvas.drawOval(ovalRect, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
