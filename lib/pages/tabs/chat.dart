import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with AutomaticKeepAliveClientMixin<Chat> {
  ServerSocket? server;
  Socket? clientSocket;
  String myIP = "Đang lấy IP...";
  final TextEditingController ipController = TextEditingController();
  bool isServer = false;
  bool isConnecting = false;
  StreamSubscription? _serverSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getMyIP();
  }

  @override
  void dispose() {
    _serverSubscription?.cancel();
    ipController.dispose();
    super.dispose();
  }

  Future<void> _getMyIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      // Find the best network interface (prefer WiFi over mobile)
      String? bestIP;
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          // Prefer 192.168.x.x or 10.x.x.x networks (common WiFi ranges)
          if (ip.startsWith('192.168.') || ip.startsWith('10.')) {
            bestIP = ip;
            break;
          } else {
            bestIP ??= ip;
          }
        }
        if (bestIP != null &&
            (bestIP.startsWith('192.168.') || bestIP.startsWith('10.'))) {
          break;
        }
      }

      if (bestIP != null && mounted) {
        setState(() {
          myIP = bestIP!;
        });
        debugPrint("Detected IP: $myIP"); // Debug log
      } else if (mounted) {
        setState(() {
          myIP = "Không tìm thấy IP";
        });
      }
    } catch (e) {
      debugPrint("Error getting IP: $e"); // Debug log
      if (mounted) {
        setState(() {
          myIP = "Lỗi lấy IP: $e";
        });
      }
    }
  }

  Future<void> _startServer() async {
    if (isConnecting || isServer) return;

    setState(() {
      isConnecting = true;
    });

    try {
      // Close existing server if any
      await _stopServer();

      server = await ServerSocket.bind(InternetAddress.anyIPv4, 3000);
      debugPrint("Server started on ${myIP}:3000"); // Debug log

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Server đang chạy tại $myIP:3000"),
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          isServer = true;
          isConnecting = false;
        });

        // Listen for incoming connections
        _serverSubscription = server!.listen(
          (Socket client) {
            debugPrint(
              "Client connected from: ${client.remoteAddress.address}:${client.remotePort}",
            ); // Debug log
            if (mounted) {
              Navigator.of(context).pushNamed(
                '/detail_chat',
                arguments: {'socket': client, 'isServer': true},
              );
            }
          },
          onError: (error) {
            debugPrint("Server error: $error"); // Debug log
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("❌ Lỗi server: $error")));
            }
          },
          onDone: () {
            debugPrint("Server closed"); // Debug log
          },
        );
      }
    } catch (e) {
      debugPrint("Error starting server: $e"); // Debug log
      if (mounted) {
        setState(() {
          isConnecting = false;
          isServer = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Lỗi khởi động server: $e"),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopServer() async {
    if (server != null) {
      await server!.close();
      server = null;
    }
    _serverSubscription?.cancel();
    _serverSubscription = null;
    if (mounted) {
      setState(() {
        isServer = false;
      });
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

    // Validate IP format
    if (!_isValidIP(serverIP)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Định dạng IP không hợp lệ")),
      );
      return;
    }

    if (isConnecting) return;

    setState(() {
      isConnecting = true;
    });

    try {
      debugPrint("Attempting to connect to $serverIP:3000"); // Debug log

      clientSocket = await Socket.connect(
        serverIP,
        3000,
        timeout: const Duration(seconds: 10), // Increased timeout
      );

      debugPrint("Connected to server successfully"); // Debug log

      if (mounted) {
        setState(() {
          isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Kết nối thành công đến $serverIP"),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushNamed(
          '/detail_chat',
          arguments: {'socket': clientSocket, 'isServer': false},
        );
      }
    } catch (e) {
      debugPrint("Connection failed: $e"); // Debug log
      if (mounted) {
        setState(() {
          isConnecting = false;
        });

        String errorMessage = "❌ Lỗi kết nối: ";
        if (e is SocketException) {
          if (e.osError?.errorCode == 111) {
            errorMessage += "Không thể kết nối - Kiểm tra IP và server";
          } else if (e.osError?.errorCode == 113) {
            errorMessage += "Không tìm thấy route đến host";
          } else {
            errorMessage += "Lỗi socket: ${e.message}";
          }
        } else if (e is TimeoutException) {
          errorMessage += "Hết thời gian chờ - Kiểm tra kết nối mạng";
        } else {
          errorMessage += e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          if (isServer)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopServer,
              tooltip: 'Dừng server',
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'IP của bạn: $myIP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (myIP != "Đang lấy IP..." &&
                        myIP != "Không tìm thấy IP" &&
                        !myIP.startsWith("Lỗi"))
                      GestureDetector(
                        onTap: () {
                          ipController.text = myIP;
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Nhấn để copy vào ô kết nối',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                  onPressed: isConnecting
                      ? null
                      : (isServer ? _stopServer : _startServer),
                  icon: isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isServer ? Icons.stop : Icons.dns),
                  label: Text(isServer ? 'Dừng Server' : 'Tạo Server'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isServer ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Nhập IP server (vd: 192.168.1.100)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer),
                        helperText: 'Cả hai thiết bị phải cùng mạng WiFi',
                        helperMaxLines: 2,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Debug info
              if (myIP != "Đang lấy IP..." && !myIP.startsWith("Lỗi"))
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Hướng dẫn:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1. Đảm bảo cả hai thiết bị cùng mạng WiFi\n'
                        '2. Một người tạo server, người còn lại kết nối\n'
                        '3. Kiểm tra tường lửa nếu không kết nối được',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
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
}
