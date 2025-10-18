import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive_lib; // Thêm tiền tố 'as rive_lib' để tránh xung đột tên
import 'dart:math'; // Import để sử dụng Random

// Chuyển sang StatefulWidget để quản lý trạng thái của Key
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // 1. Khai báo một Key duy nhất cho RiveAnimation
  Key _riveKey = UniqueKey();

  // 2. Phương thức để tải lại Animation
  void _reloadAnimation() {
    setState(() {
      // Đặt Key mới để buộc Flutter tái tạo RiveAnimation.asset
      _riveKey = UniqueKey();
    });
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

    // Logic mới: Duyệt qua chuỗi và kiểm tra từ "Rizz"
    int i = 0;
    while (i < text.length) {
      // Kiểm tra xem từ "Rizz" có bắt đầu từ vị trí i không
      if (text.length >= i + targetWord.length && text.substring(i, i + targetWord.length) == targetWord) {
        // Nếu là "Rizz", áp dụng màu hồng cho cả từ "Rizz"
        spans.add(TextSpan(text: targetWord, style: TextStyle(color: rizzColor)));
        i += targetWord.length; // Bỏ qua 4 ký tự của "Rizz"
      } else {
        // Áp dụng màu pastel ngẫu nhiên cho ký tự còn lại
        Color charColor = _pastelColors[_random.nextInt(_pastelColors.length)];
        spans.add(TextSpan(text: text[i], style: TextStyle(color: charColor)));
        i++; // Tiến lên 1 ký tự
      }
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    const String welcomeMessage = 'Chúc mừng 20/10! Bạn biết điểm chung giữa Rizz và bạn là gì không? Cả hai đều muốn làm cho mọi thứ trở nên tuyệt vời hơn. Bắt đầu trải nghiệm ngay nhé!';

    return Scaffold(
      // Bọc Stack bằng Container để thêm màu nền Gradient
      body: Container(
        decoration: BoxDecoration(
          // Dùng LinearGradient của Flutter (không cần tiền tố)
          gradient: LinearGradient(
            // Màu hồng pastel nhạt và màu trắng ngà
            colors: [
              Colors.pink.shade50.withOpacity(0.8), // Hồng nhạt (Pastel Pink)
              Colors.white, // Màu trắng ngà
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          // Căn chỉnh các widget con bên trong Stack
          alignment: Alignment.center,
          children: [
            // Widget 1: Lớp dưới cùng là animation Rive
            // Bọc RiveAnimation trong Opacity để làm mờ nhẹ, giúp màu nền xuyên qua
            Opacity(
              opacity: 0.8, // Giảm độ mờ xuống 80%
              child: rive_lib.RiveAnimation.asset(
                // 3. Áp dụng Key để kiểm soát việc tải lại
                key: _riveKey,
                'assets/animations/welcome.riv',
                fit: BoxFit.cover, // Thường dùng BoxFit.cover cho animation nền
                // artboard: 'Celebration',
                // animations: const ['Confetti'],
              ),
            ),

            // Widget 2: Lớp trên cùng là Text (Cập nhật bố cục)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 24, // Giảm kích thước chữ để phù hợp với văn bản dài hơn
                      height: 1.5, // Tăng khoảng cách dòng để dễ đọc hơn
                      fontWeight: FontWeight.w900,
                      // Màu mặc định cho các ký tự (không cần đặt màu cụ thể ở đây)
                      // color: Colors.black, // Đã loại bỏ màu mặc định
                      // Thêm hiệu ứng đổ bóng
                      shadows: const [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    children: [
                      // Sử dụng hàm _buildColoredText để tạo TextSpan với màu sắc động
                      _buildColoredText(welcomeMessage),
                    ],
                  ),
                ),
              ),
            ),

            // Widget 3: Thêm nút Reload ở phía dưới màn hình
            Positioned(
              bottom: 50,
              child: ElevatedButton.icon(
                onPressed: _reloadAnimation, // Gọi phương thức tải lại
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
}
