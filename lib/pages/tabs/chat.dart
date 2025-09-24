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
  String myIP = "Đang lấy IP...";
  final TextEditingController ipController = TextEditingController();
  bool isServer = false;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _getMyIP();
  }

  @override
  void dispose() {
    // Don't close server here as it's still needed in detail_chat
    ipController.dispose();
    super.dispose();
  }

  Future<void> _getMyIP() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      if (interfaces.isNotEmpty && mounted) {
        final ipv4Addr = interfaces.first.addresses.first.address;
        setState(() {
          myIP = ipv4Addr;
        });
      } else if (mounted) {
        setState(() {
          myIP = "Không tìm thấy IP";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          myIP = "Lỗi lấy IP";
        });
      }
    }
  }

  Future<void> _startServer() async {
    if (isConnecting) return;

    setState(() {
      isConnecting = true;
    });

    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, 3000);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Server đang chạy tại $myIP:3000")),
        );

        setState(() {
          isServer = true;
          isConnecting = false;
        });

        // Listen for incoming connections
        server!.listen((Socket client) {
          if (mounted) {
            Navigator.of(context).pushNamed(
              '/detail_chat',
              arguments: {
                'socket': client,
                'isServer': true,
              },
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi khởi động server: $e")),
        );
      }
    }
  }

  Future<void> _connectToServer() async {
    final serverIP = ipController.text.trim();
    if (serverIP.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập IP server")),
      );
      return;
    }

    if (isConnecting) return;

    setState(() {
      isConnecting = true;
    });

    try {
      clientSocket = await Socket.connect(serverIP, 3000, timeout: const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          isConnecting = false;
        });

        Navigator.of(context).pushNamed(
          '/detail_chat',
          arguments: {
            'socket': clientSocket,
            'isServer': false,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi kết nối: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
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
              const SizedBox(height: 24),

              // Server status indicator
              if (isServer)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Server đang chạy - Chờ kết nối...',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isConnecting || isServer ? null : _startServer,
                  icon: isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.dns),
                  label: Text(isServer ? 'Server đang chạy' : 'Tạo Server'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isServer ? Colors.green : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('HOẶC', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ipController,
                      enabled: !isConnecting,
                      decoration: const InputDecoration(
                        hintText: 'Nhập IP server (vd: 192.168.1.100)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isConnecting ? null : _connectToServer,
                    icon: isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
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
      ),
    );
  }
}