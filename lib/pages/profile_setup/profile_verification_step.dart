import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
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
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  bool _faceDetected = false;
  bool _isInitialized = false;
  String _instructionText = 'Position your face in the circle';
  bool _photoTaken = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startFaceDetection();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startFaceDetection() {
    if (_cameraController != null && _isInitialized) {
      _cameraController!.startImageStream(_processCameraImage);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _photoTaken) return;

    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            _faces = faces;
            _updateInstructions();
          });
        }
      }
    } catch (e) {
      debugPrint('Error detecting faces: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _updateInstructions() {
    if (_faces.isEmpty) {
      _faceDetected = false;
      _instructionText = 'Position your face in the circle';
    } else if (_faces.length > 1) {
      _faceDetected = false;
      _instructionText = 'Please ensure only one face is visible';
    } else {
      final face = _faces.first;

      // Check if face is centered and properly sized
      final faceArea = face.boundingBox.width * face.boundingBox.height;
      final screenSize = MediaQuery.of(context).size;
      final screenArea = screenSize.width * screenSize.height;
      final faceRatio = faceArea / screenArea;

      if (faceRatio < 0.1) {
        _faceDetected = false;
        _instructionText = 'Move closer to the camera';
      } else if (faceRatio > 0.4) {
        _faceDetected = false;
        _instructionText = 'Move back from the camera';
      } else {
        // Check if face is centered
        final faceCenterX = face.boundingBox.center.dx;
        final faceCenterY = face.boundingBox.center.dy;
        final screenCenterX = screenSize.width / 2;
        final screenCenterY = screenSize.height / 2;

        final offsetX = (faceCenterX - screenCenterX).abs();
        final offsetY = (faceCenterY - screenCenterY).abs();

        if (offsetX > 50 || offsetY > 50) {
          _faceDetected = false;
          _instructionText = 'Center your face in the circle';
        } else {
          _faceDetected = true;
          _instructionText = 'Perfect! Tap to capture';
        }
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;

      InputImageRotation? rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = sensorOrientation;
        rotationCompensation = (sensorOrientation + 90) % 360;
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }

      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error creating InputImage: $e');
      return null;
    }
  }

  Future<void> _capturePhoto() async {
    if (!_faceDetected || _cameraController == null || _photoTaken) return;

    try {
      await _cameraController!.stopImageStream();

      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      setState(() {
        _capturedImage = imageFile;
        _photoTaken = true;
      });

      widget.profileData.verificationPhoto = imageFile;

      // Show success message
      _showSuccessDialog();
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
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
                  color: Colors.green.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your profile has been verified',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure your face is clearly visible',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _retakePhoto() {
    setState(() {
      _photoTaken = false;
      _capturedImage = null;
      _faceDetected = false;
      _instructionText = 'Position your face in the circle';
    });

    _startFaceDetection();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: context.onSurface,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && !_photoTaken)
            Positioned.fill(child: CameraPreview(_cameraController!)),

          // Captured Photo Preview
          if (_photoTaken && _capturedImage != null)
            Positioned.fill(
              child: Image.file(_capturedImage!, fit: BoxFit.cover),
            ),

          // Face Detection Overlay
          if (_isInitialized && !_photoTaken)
            Positioned.fill(
              child: CustomPaint(
                painter: FaceDetectionPainter(
                  _faces,
                  _cameraController!.value.previewSize!,
                  MediaQuery.of(context).size,
                  _faceDetected,
                ),
              ),
            ),

          // Overlay with circle guide
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: context.onSurface.withValues(alpha: .5),
              ),
              child: CustomPaint(
                painter: CircleOverlayPainter(
                  _faceDetected,
                  context.colors.onPrimary,
                ),
              ),
            ),
          ),

          // Top Instructions
          Positioned(
            top: 18,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Text(
                  'Profile verification',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We use AI technology to verify your profile images with the selfie image to order to make sure that you have uploaded real images of you.',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colors.onPrimary.withValues(alpha: .9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _instructionText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _faceDetected
                        ? Colors.green
                        : context.colors.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (!_photoTaken) ...[
                  // Capture Button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _faceDetected
                            ? context.primary
                            : context.onSurface.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.onPrimary,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        Icons.camera,
                        color: context.colors.onPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                ] else ...[
                  // Retake and Continue Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _retakePhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.surface,
                          foregroundColor: context.onSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retake'),
                      ),
                      ElevatedButton(
                        onPressed: () => _showSuccessDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primary,
                          foregroundColor: context.colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Loading indicator
          if (!_isInitialized)
            Center(child: CircularProgressIndicator(color: context.primary)),
        ],
      ),
    );
  }
}

class CircleOverlayPainter extends CustomPainter {
  final bool faceDetected;
  final Color borderColor;

  CircleOverlayPainter(this.faceDetected, this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    final center = Offset(size.width / 2, size.height / 2 - 50);
    const radius = 120.0;

    // Draw the transparent circle
    canvas.drawCircle(center, radius, paint);

    // Draw the circle border
    final borderPaint = Paint()
      ..color = faceDetected ? Colors.green : borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class FaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final Size previewSize;
  final Size screenSize;
  final bool faceDetected;

  FaceDetectionPainter(
    this.faces,
    this.previewSize,
    this.screenSize,
    this.faceDetected,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = faceDetected ? Colors.green : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final face in faces) {
      final rect = _scaleRect(face.boundingBox, previewSize, screenSize);
      canvas.drawRect(rect, paint);
    }
  }

  Rect _scaleRect(Rect rect, Size previewSize, Size screenSize) {
    final scaleX = screenSize.width / previewSize.height;
    final scaleY = screenSize.height / previewSize.width;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
