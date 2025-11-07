import 'dart:async'; // Để dùng Future.delayed
import 'dart:math'; // Import để sử dụng Random

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

// Chuyển sang StatefulWidget để quản lý trạng thái của Key
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Biến trạng thái để điều khiển animation của Text
  bool _textVisible = false;

  // Rive animation controller
  RiveWidgetController? _riveController;
  bool _riveLoaded = false;

  @override
  void initState() {
    super.initState();
    // Preload Rive animation
    _preloadRiveAnimation();
    // Kích hoạt animation sau một khoảng trễ ngắn (ví dụ: 300ms)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // Kiểm tra widget còn tồn tại trước khi gọi setState
        setState(() {
          _textVisible = true;
        });
      }
    });
  }

  // Preload Rive animation
  Future<void> _preloadRiveAnimation() async {
    try {
      final file = await File.asset(
        'assets/animations/confettis.riv',
        riveFactory: Factory.rive,
      );

      if (file != null) {
        _riveController = RiveWidgetController(file);
        _riveLoaded = true;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Failed to preload Rive animation: $e');
      _riveLoaded = false;
    }
  }

  // Danh sách các màu pastel
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

  final Random _random = Random(); // Đối tượng Random để lấy màu ngẫu nhiên

  // Hàm để tạo TextSpan với màu ngẫu nhiên (hoặc màu hồng cho "Rizz")
  TextSpan _buildColoredText(String text) {
    List<TextSpan> spans = [];
    const String targetWord = "Rizz";
    Color rizzColor = Colors.pink.shade400; // Màu hồng đậm hơn cho chữ "Rizz"

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

  @override
  Widget build(BuildContext context) {
    const String welcomeMessage =
        'Rizz chúc bạn một ngày 20/10 thật rực rỡ và đầy yêu thương';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade50.withOpacity(0.8), // Hồng nhạt (Pastel Pink)
              Colors.white, // Màu trắng ngà
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Widget 1: Lớp dưới cùng là animation Rive
            if (_riveLoaded && _riveController != null)
              Opacity(
                opacity: 0.8,
                child: RiveWidget(controller: _riveController!, fit: Fit.cover),
              )
            else
              // Fallback while loading
              Container(),

            // Widget 2: Lớp trên cùng là Text (Cập nhật bố cục)
            Center(
              // THAY ĐỔI: Dùng AnimatedScale thay cho AnimatedSlide
              child: AnimatedScale(
                // MỚI: Scale từ 0 (biến mất) lên 1 (bình thường)
                scale: _textVisible ? 1.0 : 0.0,
                duration: const Duration(
                  milliseconds: 600,
                ), // Thời gian "bật" ra
                // MỚI: Đây là chìa khóa để tạo hiệu ứng "bật" (nảy ra)
                // Nó sẽ đi lố 1.0 một chút rồi quay lại
                curve: Curves.easeOutBack,

                child: AnimatedOpacity(
                  // Mờ dần từ 0.0 -> 1.0
                  opacity: _textVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500), // Thời gian mờ
                  curve: Curves.easeIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          height: 1.5,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black45,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                        children: [_buildColoredText(welcomeMessage)],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Widget 3: Thêm nút Reload ở phía dưới màn hình
            Positioned(
              bottom: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _textVisible = false;
                  });
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        _textVisible = true;
                      });
                    }
                  });
                }, // Gọi phương thức tải lại
                icon: const Icon(Icons.refresh, color: Colors.indigo),
                label: const Text(
                  'Tải lại Animation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.indigo, width: 2),
                  ),
                  elevation: 10,
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
    _riveController?.dispose();
    super.dispose();
  }
}
