import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive_lib; // Thêm tiền tố 'as rive_lib' để tránh xung đột tên

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

  @override
  Widget build(BuildContext context) {
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

            // Widget 2: Lớp trên cùng là Text
            // Được bọc trong Center để đảm bảo nó nằm chính giữa
            const Center(
              child: Text(
                'Chào mừng bạn!',
                style: TextStyle(
                  fontSize: 40, // Cỡ chữ lớn
                  fontWeight: FontWeight.bold, // In đậm
                  color: Colors.white, // Màu trắng
                  // Thêm hiệu ứng đổ bóng để chữ nổi bật hơn trên nền animation
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black87, // Đổi màu bóng sang đen đậm hơn để nổi bật trên nền nhạt
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
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
