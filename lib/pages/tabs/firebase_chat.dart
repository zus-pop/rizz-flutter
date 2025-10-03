import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rizz_mobile/services/firebase_chat_service.dart';
import 'package:rizz_mobile/pages/details/firebase_detail_chat.dart';

class FirebaseChat extends StatefulWidget {
  const FirebaseChat({super.key});

  @override
  State<FirebaseChat> createState() => _FirebaseChatState();
}

class _FirebaseChatState extends State<FirebaseChat> with AutomaticKeepAliveClientMixin<FirebaseChat> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _joinRoomController = TextEditingController();
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _roomNameController.dispose();
    _joinRoomController.dispose();
    super.dispose();
  }

  Future<void> _createPublicRoom() async {
    final roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) {
      _showSnackBar('⚠️ Vui lòng nhập tên phòng chat');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final chatRoomId = await FirebaseChatService.createPublicChatRoom(roomName);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _roomNameController.clear();
        _showSnackBar('✅ Tạo phòng chat thành công!');

        // Navigate to the chat room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FirebaseDetailChat(
              chatRoomId: chatRoomId,
              chatRoomName: roomName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('❌ Lỗi tạo phòng: $e');
      }
    }
  }

  Future<void> _joinRoom(String chatRoomId, String roomName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseChatService.joinPublicChatRoom(chatRoomId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FirebaseDetailChat(
              chatRoomId: chatRoomId,
              chatRoomName: roomName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('❌ Lỗi tham gia phòng: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Firebase Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Realtime chat với Firebase',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Create Room Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.green.shade400),
                        const SizedBox(width: 8),
                        const Text(
                          'Tạo phòng chat mới',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roomNameController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên phòng chat...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.meeting_room),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createPublicRoom,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(_isLoading ? 'Đang tạo...' : 'Tạo phòng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Public Rooms List
              Row(
                children: [
                  Icon(Icons.public, color: Colors.blue.shade400),
                  const SizedBox(width: 8),
                  const Text(
                    'Phòng chat công khai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: FirebaseChatService.getPublicChatRoomsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi tải danh sách phòng',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final rooms = snapshot.data ?? [];

                    if (rooms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.grey.shade400,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có phòng chat nào',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy tạo phòng chat đầu tiên!',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final data = room.data() as Map<String, dynamic>;
                        final roomName = data['roomName'] ?? 'Unknown Room';
                        final participants = List<String>.from(data['participants'] ?? []);
                        final lastMessage = data['lastMessage'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  Icons.group,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              title: Text(
                                roomName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${participants.length} thành viên',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (lastMessage != null)
                                    Text(
                                      lastMessage,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () => _joinRoom(room.id, roomName),
                                icon: Icon(
                                  Icons.login,
                                  color: Colors.green.shade400,
                                ),
                                tooltip: 'Tham gia',
                              ),
                              onTap: () => _joinRoom(room.id, roomName),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}