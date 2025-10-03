import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng Stack để xếp chồng các widget lên nhau
      body: Stack(
        // Căn chỉnh các widget con bên trong Stack
        alignment: Alignment.center,
        children: [
          // Widget 1: Lớp dưới cùng là animation Lottåie
          // Animation sẽ lấp đầy toàn bộ màn hình
          Lottie.asset(
            'assets/animations/Confetti.json', // <-- Đường dẫn đến file Lottie của bạn
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
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
                    color: Colors.black54,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}