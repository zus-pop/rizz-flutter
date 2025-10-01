import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/simple_chat_service.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with AutomaticKeepAliveClientMixin<Chat> {
  String? currentRoomId;
  String? roomCode;
  final TextEditingController roomCodeController = TextEditingController();
  bool isCreatingRoom = false;
  bool isJoiningRoom = false;
  bool isInRoom = false;
  bool firestoreEnabled = false;
  bool checkingFirestore = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    roomCodeController.dispose();
    if (currentRoomId != null) {
      SimpleChatService.leaveChatRoom(currentRoomId!);
    }
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() {
      checkingFirestore = true;
    });

    try {
      await SimpleChatService.ensureAuthenticated();

      // Try a simple test to check if Firestore is working
      await _testFirestoreConnection();

    } catch (e) {
      debugPrint("Error initializing service: $e");
      if (mounted) {
        setState(() {
          checkingFirestore = false;
          firestoreEnabled = false;
        });

        if (e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('firestore.googleapis.com') ||
            e.toString().contains('Cloud Firestore API has not been used') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('Firestore API not enabled')) {
          // Don't show snackbar here, we'll show the setup dialog when user tries to use the feature
          debugPrint("Firestore API not enabled - will show setup dialog when needed");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Lỗi khởi tạo dịch vụ: $e")),
          );
        }
      }
    }
  }

  Future<void> _testFirestoreConnection() async {
    try {
      // Try to read from Firestore to test connection
      await SimpleChatService.testConnection();

      if (mounted) {
        setState(() {
          checkingFirestore = false;
          firestoreEnabled = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          checkingFirestore = false;
          firestoreEnabled = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _createChatRoom() async {
    if (isCreatingRoom) return;

    setState(() {
      isCreatingRoom = true;
    });

    try {
      currentRoomId = await SimpleChatService.createChatRoom();
      final roomInfo = await SimpleChatService.getRoomInfo(currentRoomId!);

      if (mounted && roomInfo != null) {
        final newRoomCode = roomInfo['room_code'];
        debugPrint('Room created with code: $newRoomCode');

        setState(() {
          roomCode = newRoomCode;
          isInRoom = true;
          isCreatingRoom = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Phòng chat đã tạo! Mã phòng: $newRoomCode\nChia sẻ mã này để người khác tham gia"),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: newRoomCode));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("📋 Đã copy mã phòng!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
      } else {
        throw Exception('Không thể lấy thông tin phòng chat');
      }
    } catch (e) {
      debugPrint("Error creating chat room: $e");
      if (mounted) {
        setState(() {
          isCreatingRoom = false;
        });

        // Check if it's a Firestore API issue
        if (e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('firestore.googleapis.com') ||
            e.toString().contains('Cloud Firestore API has not been used')) {
          _showFirestoreSetupDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Lỗi tạo phòng chat: $e")),
          );
        }
      }
    }
  }

  Future<void> _joinChatRoom() async {
    final roomCodeInput = roomCodeController.text.trim().toUpperCase();
    if (roomCodeInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập mã phòng")),
      );
      return;
    }

    if (isJoiningRoom) return;

    setState(() {
      isJoiningRoom = true;
    });

    try {
      currentRoomId = await SimpleChatService.joinChatRoom(roomCodeInput);

      if (mounted) {
        setState(() {
          roomCode = roomCodeInput;
          isInRoom = true;
          isJoiningRoom = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Đã tham gia phòng chat: $roomCodeInput"),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to chat detail page
        Navigator.of(context).pushNamed(
          '/detail_chat',
          arguments: {
            'roomId': currentRoomId,
            'roomCode': roomCode,
            'isFirebaseChat': false,
          },
        );
      }
    } catch (e) {
      debugPrint("Error joining chat room: $e");
      if (mounted) {
        setState(() {
          isJoiningRoom = false;
        });

        // Check if it's a Firestore API issue
        if (e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('firestore.googleapis.com') ||
            e.toString().contains('Cloud Firestore API has not been used')) {
          _showFirestoreSetupDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ $e"),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _leaveChatRoom() async {
    if (currentRoomId != null) {
      await SimpleChatService.leaveChatRoom(currentRoomId!);
    }
    setState(() {
      currentRoomId = null;
      roomCode = null;
      isInRoom = false;
    });
    roomCodeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Đã rời khỏi phòng chat")),
    );
  }

  void _openChatRoom() {
    if (currentRoomId != null && roomCode != null) {
      Navigator.of(context).pushNamed(
        '/detail_chat',
        arguments: {
          'roomId': currentRoomId,
          'roomCode': roomCode,
          'isFirebaseChat': false,
        },
      );
    }
  }

  void _showFirestoreSetupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text("Cần Kích Hoạt Firestore"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cloud Firestore API chưa được kích hoạt cho dự án Firebase của bạn.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Automated setup section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "✨ CÁCH NHANH NHẤT:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("1. Chạy file setup_firestore.bat trong thư mục dự án"),
                    const Text("2. Làm theo hướng dẫn trong script"),
                    const Text("3. Khởi động lại ứng dụng"),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text("Hoặc làm theo cách thủ công:"),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("1. Mở Google Cloud Console"),
                    const Text("2. Chọn dự án: rizz-7e0b8"),
                    const Text("3. Tìm 'Cloud Firestore API'"),
                    const Text("4. Nhấn 'Enable'"),
                    const Text("5. Tạo Firestore database trong Firebase Console"),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Link trực tiếp:",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                "https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=rizz-7e0b8",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(
                  text: "https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=rizz-7e0b8"
                ));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("📋 Đã copy link vào clipboard!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text("Copy Link"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Try to test connection again after user potentially fixed the issue
                _testFirestoreConnection();
              },
              child: const Text("Kiểm tra lại"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với Mã Phòng'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          if (isInRoom)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _leaveChatRoom,
              tooltip: 'Rời phòng chat',
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat,
                      size: 48,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chat với Mã Phòng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo phòng và chia sẻ mã\nhoặc nhập mã để tham gia',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Firestore Status Indicator
              if (checkingFirestore || !firestoreEnabled)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: checkingFirestore
                        ? Colors.blue.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: checkingFirestore
                          ? Colors.blue.shade200
                          : Colors.red.shade200
                    ),
                  ),
                  child: Row(
                    children: [
                      if (checkingFirestore)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.warning,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checkingFirestore
                                  ? "Đang kiểm tra kết nối Firestore..."
                                  : "Firestore API chưa được kích hoạt",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: checkingFirestore
                                    ? Colors.blue.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                            if (!checkingFirestore && !firestoreEnabled)
                              Text(
                                "Nhấn 'Tạo Phòng Chat' để xem hướng dẫn cài đặt",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (checkingFirestore || !firestoreEnabled)
                const SizedBox(height: 24),

              // Current room status
              if (isInRoom && roomCode != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Đang trong phòng:',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          roomCode!,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _openChatRoom,
                        icon: const Icon(Icons.chat),
                        label: const Text('Mở Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isInRoom) ...[
                // Create room button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isCreatingRoom ? null : _createChatRoom,
                    icon: isCreatingRoom
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add),
                    label: Text(isCreatingRoom ? 'Đang tạo phòng...' : 'Tạo Phòng Chat Mới'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Join room section
                Text(
                  'Hoặc tham gia phòng có sẵn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: roomCodeController,
                  enabled: !isJoiningRoom,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã phòng (VD: ABC123)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.meeting_room),
                    helperText: 'Mã phòng gồm 6 ký tự',
                    helperStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  onSubmitted: (_) => _joinChatRoom(),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isJoiningRoom ? null : _joinChatRoom,
                    icon: isJoiningRoom
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: Text(isJoiningRoom ? 'Đang tham gia...' : 'Tham Gia Phòng'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hướng dẫn sử dụng:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInstructionRow('1', 'Tạo phòng chat mới và nhận mã phòng 6 ký tự'),
                        const SizedBox(height: 8),
                        _buildInstructionRow('2', 'Chia sẻ mã phòng với người muốn chat'),
                        const SizedBox(height: 8),
                        _buildInstructionRow('3', 'Nhập mã phòng để tham gia và bắt đầu chat'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
