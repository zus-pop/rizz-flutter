import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class DetailChat extends StatefulWidget {
  const DetailChat({super.key});

  @override
  State<DetailChat> createState() => _DetailChatState();
}

class _DetailChatState extends State<DetailChat> {
  Socket? socket;
  bool isServer = false;
  final List<String> messages = [];
  final TextEditingController messageController = TextEditingController();
  StreamSubscription? socketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      setState(() {
        socket = args['socket'];
        isServer = args['isServer'] ?? false;
      });
      _listenToSocket();
    }
  }

  @override
  void dispose() {
    socketSubscription?.cancel();
    socket?.destroy();
    messageController.dispose();
    super.dispose();
  }

  void _listenToSocket() {
    if (socket == null) return;

    socketSubscription = socket!.listen(
      (data) {
        if (mounted) {
          final message = String.fromCharCodes(data);
          setState(() {
            messages.add(isServer ? "Client: $message" : "Server: $message");
          });
        }
      },
      onDone: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Đối phương đã ngắt kết nối")),
          );
          _returnToMainScreen();
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Lỗi kết nối: $error")),
          );
          _returnToMainScreen();
        }
      },
      cancelOnError: false,
    );
  }

  void _sendMessage() {
    String message = messageController.text.trim();
    if (message.isEmpty || socket == null) return;

    try {
      socket!.write(message);
      if (mounted) {
        setState(() {
          messages.add("Tôi: $message");
        });
      }
      messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi gửi tin nhắn: $e")),
        );
      }
    }
  }

  void _returnToMainScreen() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isServer ? 'Chat với Client' : 'Chat với Server'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _returnToMainScreen,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMyMessage = message.startsWith('Tôi:');

                return Align(
                  alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isMyMessage ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isMyMessage ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
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