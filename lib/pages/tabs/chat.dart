import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  ServerSocket? server;
  Socket? clientSocket;
  final List<String> messages = [];
  final TextEditingController messageController = TextEditingController();
  final TextEditingController ipController = TextEditingController();
  String myIP = "Đang lấy IP...";
  bool isServer = false;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _getMyIP();
  }

  @override
  void dispose() {
    server?.close();
    clientSocket?.close();
    messageController.dispose();
    ipController.dispose();
    super.dispose();
  }

  void _getMyIP() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      if (interfaces.isNotEmpty) {
        final ipv4Addr = interfaces.first.addresses.first.address;
        setState(() {
          myIP = ipv4Addr;
        });
      } else {
        setState(() {
          myIP = "Không tìm thấy IP";
        });
      }
    } catch (e) {
      setState(() {
        myIP = "Lỗi lấy IP";
      });
    }
  }

  void _startServer() async {
    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, 3000);
      setState(() {
        isServer = true;
        messages.add("✅ Server đang chạy tại $myIP:3000");
      });

      server!.listen((Socket client) {
        if (!isConnected) {
          setState(() {
            clientSocket = client;
            isConnected = true;
            messages.add("🔗 Client kết nối từ: ${client.remoteAddress.address}");
          });

          client.listen(
                (data) {
              final message = String.fromCharCodes(data);
              setState(() {
                messages.add("Client: $message");
              });
            },
            onDone: () {
              setState(() {
                isConnected = false;
                clientSocket?.close();
                clientSocket = null;
                messages.add("❌ Client ngắt kết nối");
              });
            },
            onError: (error) {
              setState(() {
                isConnected = false;
                clientSocket?.close();
                clientSocket = null;
                messages.add("❌ Lỗi: $error");
              });
            },
          );
        } else {
          client.close();
        }
      });
    } catch (e) {
      setState(() {
        messages.add("❌ Lỗi khởi động server: $e");
      });
    }
  }

  void _connectToServer() async {
    try {
      String serverIP = ipController.text.trim();
      if (serverIP.isEmpty) {
        setState(() {
          messages.add("⚠️ Vui lòng nhập IP server");
        });
        return;
      }

      clientSocket = await Socket.connect(serverIP, 3000);
      setState(() {
        isConnected = true;
        messages.add("✅ Đã kết nối tới server $serverIP:3000");
      });

      clientSocket!.listen(
            (data) {
          final message = String.fromCharCodes(data);
          setState(() {
            messages.add("Server: $message");
          });
        },
        onDone: () {
          setState(() {
            isConnected = false;
            clientSocket?.close();
            clientSocket = null;
            messages.add("❌ Mất kết nối với server");
          });
        },
        onError: (error) {
          setState(() {
            isConnected = false;
            clientSocket?.close();
            clientSocket = null;
            messages.add("❌ Lỗi: $error");
          });
        },
      );
    } catch (e) {
      setState(() {
        messages.add("❌ Lỗi kết nối: $e");
      });
    }
  }

  void _sendMessage() {
    String message = messageController.text.trim();
    if (message.isEmpty || !isConnected || clientSocket == null) return;

    clientSocket!.write(message);
    setState(() {
      messages.add("Tôi: $message");
    });
    messageController.clear();
  }

  void _disconnect() {
    server?.close();
    clientSocket?.close();
    setState(() {
      isServer = false;
      isConnected = false;
      server = null;
      clientSocket = null;
      messages.add("🔌 Đã ngắt kết nối");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Chat')),
        backgroundColor: Colors.blue,
        actions: [
          if (isServer || isConnected)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: _disconnect,
              tooltip: 'Ngắt kết nối',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Text(
              'IP của bạn: $myIP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (isServer || isConnected) ? null : _startServer,
                    icon: const Icon(Icons.dns),
                    label: const Text('Tạo Server'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ipController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập IP server (vd: 192.168.1.100)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.computer),
                        ),
                        enabled: !isServer && !isConnected,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: (isServer || isConnected) ? null : _connectToServer,
                      icon: const Icon(Icons.link),
                      label: const Text('Kết nối'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMyMessage = message.startsWith('Tôi:');
                final isSystemMessage = message.contains('✅') ||
                    message.contains('❌') ||
                    message.contains('🔗') ||
                    message.contains('⚠️') ||
                    message.contains('🔌');

                if (isSystemMessage) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

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
                        hintText: isConnected ? 'Nhập tin nhắn...' : 'Kết nối để chat',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      enabled: isConnected,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: isConnected ? Colors.blue : Colors.grey,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: isConnected ? _sendMessage : null,
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