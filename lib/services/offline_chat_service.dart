import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class OfflineChatService {
  static String? _currentUserId;
  static String? _currentUserName;
  static final Map<String, Map<String, dynamic>> _chatRooms = {};
  static final Map<String, List<Map<String, dynamic>>> _roomMessages = {};
  static final Map<String, StreamController<List<Map<String, dynamic>>>> _messageStreams = {};

  // Lightweight network discovery
  static HttpServer? _server;
  static Timer? _discoveryTimer;
  static RawDatagramSocket? _udpSocket;
  static final Set<String> _knownDevices = {};
  static int _serverPort = 8080;
  static int _udpPort = 8888;
  static String? _localIp;
  static bool _isEmulator = false;

  // Stream for broadcasting available rooms
  static final StreamController<List<Map<String, dynamic>>> _availableRoomsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Generate a simple user ID
  static void _generateUserId() {
    if (_currentUserId == null) {
      final random = Random();
      _currentUserId = 'user_${random.nextInt(999999).toString().padLeft(6, '0')}';
      _currentUserName = 'User${random.nextInt(9999).toString().padLeft(4, '0')}';
      debugPrint('Generated user ID: $_currentUserId, name: $_currentUserName');
    }
  }

  // Lightweight HTTP server
  static Future<void> _startLightweightServer() async {
    try {
      // Get local IP first
      _localIp = await _getLocalIp();
      if (_localIp == null) {
        debugPrint('Could not get local IP');
        return;
      }

      // Find available port quickly
      for (int port = 8080; port <= 8085; port++) {
        try {
          _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
          _serverPort = port;
          debugPrint('Lightweight server started on $_localIp:$_serverPort');
          break;
        } catch (e) {
          continue;
        }
      }

      if (_server == null) return;

      // Simple request handler
      _server!.listen((HttpRequest request) async {
        try {
          final response = request.response;
          response.headers.set('Access-Control-Allow-Origin', '*');

          if (request.method == 'GET' && request.uri.path == '/ping') {
            // Simple ping response
            response.write(jsonEncode({
              'status': 'ok',
              'device_id': _currentUserId,
              'device_name': _currentUserName,
              'room_count': _chatRooms.length,
            }));
          } else if (request.method == 'GET' && request.uri.path == '/rooms') {
            // Return only active local rooms
            final localRooms = _chatRooms.values
                .where((room) => room['is_active'] == true && room['is_remote'] != true)
                .map((room) => _serializeRoom(room))
                .toList();

            response.write(jsonEncode({
              'rooms': localRooms,
              'device_id': _currentUserId,
            }));
          } else if (request.method == 'POST' && request.uri.path == '/join') {
            // Handle join requests
            final body = await utf8.decoder.bind(request).join();
            final data = jsonDecode(body);
            await _handleRemoteJoin(data);
            response.write(jsonEncode({'success': true}));
          }

          await response.close();
        } catch (e) {
          debugPrint('Request handling error: $e');
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          } catch (_) {}
        }
      });

      // Start lightweight discovery
      _startLightweightDiscovery();
    } catch (e) {
      debugPrint('Error starting server: $e');
    }
  }

  // Get local IP efficiently - support all private IP ranges
  static Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String? fallbackIp;

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) {
            final ip = address.address;

            // Check for private IP ranges
            if (ip.startsWith('192.168.') ||    // Class C private
                ip.startsWith('10.') ||          // Class A private
                (ip.startsWith('172.') && _isClassBPrivate(ip))) { // Class B private
              debugPrint('Found private IP: $ip on interface: ${interface.name}');
              return ip;
            }

            // Keep any non-loopback IP as fallback
            if (fallbackIp == null && !ip.startsWith('127.')) {
              fallbackIp = ip;
            }
          }
        }
      }

      // If no private IP found, use any available IP
      if (fallbackIp != null) {
        debugPrint('Using fallback IP: $fallbackIp');
        return fallbackIp;
      }

      debugPrint('No suitable IP address found');
      return null;
    } catch (e) {
      debugPrint('Error getting local IP: $e');
      return null;
    }
  }

  // Check if IP is in Class B private range (172.16.0.0 to 172.31.255.255)
  static bool _isClassBPrivate(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length != 4 || !parts[0].startsWith('172')) return false;

      final secondOctet = int.parse(parts[1]);
      return secondOctet >= 16 && secondOctet <= 31;
    } catch (e) {
      return false;
    }
  }

  // Lightweight discovery - simplified for manual room codes
  static void _startLightweightDiscovery() {
    _discoveryTimer?.cancel();

    // Check if running on emulator
    _isEmulator = _localIp?.startsWith('10.0.2.') == true;

    if (_isEmulator) {
      debugPrint('Running on Android Emulator - manual room code entry only');
      // No automatic discovery for emulator
    } else {
      debugPrint('Running on real device - manual room code entry only');
      // No automatic discovery for real devices either
    }
  }

  // Scan host machine from emulator - improved
  static Future<void> _scanHostMachine() async {
    try {
      // 10.0.2.2 is the host machine IP from emulator perspective
      const hostIp = '10.0.2.2';

      // Try different ports where host might be running Flutter app
      final hostPorts = [8080, 8081, 8082, 8083, 8084, 8085];

      for (final port in hostPorts) {
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(milliseconds: 800);

          final request = await client.get(hostIp, port, '/ping');
          final response = await request.close().timeout(const Duration(milliseconds: 1500));

          if (response.statusCode == 200) {
            final body = await utf8.decoder.bind(response).join();
            final data = jsonDecode(body);

            final deviceKey = '$hostIp:$port';
            if (!_knownDevices.contains(deviceKey)) {
              _knownDevices.add(deviceKey);
              debugPrint('✅ Emulator found real device: $deviceKey (${data['device_name']})');
            }

            // Get rooms from host
            await _fetchRoomsFromDevice(hostIp, port);
            break; // Found working port
          }

          client.close();
        } catch (e) {
          // Continue trying other ports
        }
      }

      // Also try to scan some common network ranges that might be bridged
      await _scanBridgedNetworks();

    } catch (e) {
      debugPrint('Emulator host scan error: $e');
    }
  }

  // Try to scan bridged networks from emulator
  static Future<void> _scanBridgedNetworks() async {
    try {
      // Common bridged network ranges
      final bridgedRanges = ['192.168.1', '192.168.0', '10.0.0'];

      for (final range in bridgedRanges) {
        final commonIps = [
          '$range.1',   // Router
          '$range.2',   // Common device
          '$range.10',  // Common device
          '$range.100', // Common device
        ];

        for (final ip in commonIps) {
          try {
            final client = HttpClient();
            client.connectionTimeout = const Duration(milliseconds: 300);

            final request = await client.get(ip, 8080, '/ping');
            final response = await request.close().timeout(const Duration(milliseconds: 500));

            if (response.statusCode == 200) {
              final body = await utf8.decoder.bind(response).join();
              final data = jsonDecode(body);

              final deviceKey = '$ip:8080';
              if (!_knownDevices.contains(deviceKey)) {
                _knownDevices.add(deviceKey);
                debugPrint('✅ Emulator found bridged device: $deviceKey (${data['device_name']})');
              }

              await _fetchRoomsFromDevice(ip, 8080);
            }

            client.close();
          } catch (e) {
            // Continue trying other IPs
          }
        }
      }
    } catch (e) {
      // Ignore bridged network scan errors
    }
  }

  // Quick scan for available devices
  static Future<void> _quickScan() async {
    if (_localIp == null) return;

    try {
      final parts = _localIp!.split('.');
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

      // Only scan a few common device IPs instead of all 254
      final commonIps = [
        '$subnet.1',   // Router
        '$subnet.2',   // Common device
        '$subnet.10',  // Common device
        '$subnet.20',  // Common device
        '$subnet.100', // Common device
        '$subnet.101', // Common device
        '$subnet.102', // Common device
      ];

      // Add any previously discovered IPs
      for (final device in _knownDevices) {
        final ip = device.split(':')[0];
        if (!commonIps.contains(ip)) {
          commonIps.add(ip);
        }
      }

      // Quick concurrent scan
      final futures = commonIps.where((ip) => ip != _localIp).map((ip) => _quickCheck(ip));
      await Future.wait(futures).timeout(const Duration(seconds: 1), onTimeout: () => []);

    } catch (e) {
      debugPrint('Quick scan error: $e');
    }
  }

  static Future<void> _quickCheck(String ip) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 300);

      for (int port = 8080; port <= 8085; port++) {
        try {
          final request = await client.get(ip, port, '/ping');
          final response = await request.close().timeout(const Duration(milliseconds: 500));

          if (response.statusCode == 200) {
            final deviceKey = '$ip:$port';
            if (!_knownDevices.contains(deviceKey)) {
              _knownDevices.add(deviceKey);
              debugPrint('Found device: $deviceKey');
            }

            // Get rooms from this device
            await _fetchRoomsFromDevice(ip, port);
            break; // Found working port, no need to try others
          }
        } catch (e) {
          // Ignore errors for quick scan
        }
      }

      client.close();
    } catch (e) {
      // Ignore scan errors
    }
  }

  static Future<void> _fetchRoomsFromDevice(String ip, int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 300);

      final request = await client.get(ip, port, '/rooms');
      final response = await request.close().timeout(const Duration(milliseconds: 500));

      if (response.statusCode == 200) {
        final body = await utf8.decoder.bind(response).join();
        final data = jsonDecode(body);

        if (data['rooms'] != null) {
          await _mergeRemoteRooms(data['rooms'], ip, port);
        }
      }

      client.close();
    } catch (e) {
      // Ignore fetch errors
    }
  }

  // Serialize room for network transfer
  static Map<String, dynamic> _serializeRoom(Map<String, dynamic> room) {
    final copy = Map<String, dynamic>.from(room);
    if (copy['created_at'] is DateTime) {
      copy['created_at'] = (copy['created_at'] as DateTime).toIso8601String();
    }
    if (copy['last_message_at'] is DateTime) {
      copy['last_message_at'] = (copy['last_message_at'] as DateTime).toIso8601String();
    }
    return copy;
  }

  // Handle remote join request
  static Future<void> _handleRemoteJoin(Map<String, dynamic> data) async {
    try {
      final roomId = data['room_id'];
      final userId = data['user_id'];

      if (_chatRooms.containsKey(roomId)) {
        final participants = List<String>.from(_chatRooms[roomId]!['participants'] ?? []);
        if (!participants.contains(userId)) {
          participants.add(userId);
          _chatRooms[roomId]!['participants'] = participants;
          _chatRooms[roomId]!['participant_count'] = participants.length;
          _broadcastAvailableRooms();
        }
      }
    } catch (e) {
      debugPrint('Handle remote join error: $e');
    }
  }

  // Merge remote rooms (lightweight)
  static Future<void> _mergeRemoteRooms(List<dynamic> remoteRooms, String ip, int port) async {
    try {
      for (final room in remoteRooms) {
        final roomId = room['id'];
        final roomData = Map<String, dynamic>.from(room);

        // Convert timestamps
        if (roomData['created_at'] is String) {
          roomData['created_at'] = DateTime.parse(roomData['created_at']);
        }
        if (roomData['last_message_at'] is String) {
          roomData['last_message_at'] = DateTime.parse(roomData['last_message_at']);
        }

        // Mark as remote
        roomData['is_remote'] = true;
        roomData['remote_host'] = ip;
        roomData['remote_port'] = port;

        // Only add if not exists locally
        if (!_chatRooms.containsKey(roomId)) {
          _chatRooms[roomId] = roomData;
        }
      }

      _broadcastAvailableRooms();
    } catch (e) {
      debugPrint('Merge remote rooms error: $e');
    }
  }

  // Broadcast available rooms to all listeners
  static void _broadcastAvailableRooms() {
    try {
      final availableRooms = _chatRooms.values
          .where((room) => room['is_active'] == true)
          .map((room) => Map<String, dynamic>.from(room))
          .toList();

      // Sort by creation time (newest first)
      availableRooms.sort((a, b) {
        final aTime = a['created_at'] as DateTime;
        final bTime = b['created_at'] as DateTime;
        return bTime.compareTo(aTime);
      });

      _availableRoomsController.add(availableRooms);
      debugPrint('Broadcasting ${availableRooms.length} available rooms');
    } catch (e) {
      debugPrint('Broadcast error: $e');
    }
  }

  // Get stream of available rooms
  static Stream<List<Map<String, dynamic>>> getAvailableRoomsStream() {
    Future.delayed(Duration.zero, () {
      _broadcastAvailableRooms();
    });
    return _availableRoomsController.stream;
  }

  // Create a chat room
  static Future<String> createChatRoom() async {
    try {
      _generateUserId();

      final roomCode = _generateRoomCode();
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';

      _chatRooms[roomId] = {
        'id': roomId,
        'created_at': DateTime.now(),
        'created_by': _currentUserId,
        'creator_name': _currentUserName,
        'participants': [_currentUserId],
        'is_active': true,
        'room_code': roomCode,
        'last_message': '',
        'last_message_at': DateTime.now(),
        'participant_count': 1,
      };

      _roomMessages[roomId] = [];
      _messageStreams[roomId] = StreamController<List<Map<String, dynamic>>>.broadcast();

      _broadcastAvailableRooms();
      debugPrint('Chat room created: $roomId');
      return roomId;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      rethrow;
    }
  }

  // Join a chat room using room code
  static Future<String> joinChatRoom(String roomCode) async {
    try {
      _generateUserId();

      // Find room by code
      String? foundRoomId;
      for (var entry in _chatRooms.entries) {
        if (entry.value['room_code'] == roomCode && entry.value['is_active'] == true) {
          foundRoomId = entry.key;
          break;
        }
      }

      if (foundRoomId == null) {
        throw Exception('Không tìm thấy phòng chat với mã này');
      }

      return await joinChatRoomById(foundRoomId);
    } catch (e) {
      debugPrint('Error joining chat room by code: $e');
      rethrow;
    }
  }

  // Join a chat room directly by room ID
  static Future<String> joinChatRoomById(String roomId) async {
    try {
      _generateUserId();

      if (!_chatRooms.containsKey(roomId)) {
        throw Exception('Phòng chat không tồn tại');
      }

      final roomData = _chatRooms[roomId]!;

      if (roomData['is_remote'] == true) {
        await _joinRemoteRoom(roomData);
      } else {
        final participants = List<String>.from(roomData['participants'] ?? []);
        if (!participants.contains(_currentUserId)) {
          participants.add(_currentUserId!);
          _chatRooms[roomId]!['participants'] = participants;
          _chatRooms[roomId]!['participant_count'] = participants.length;
        }
      }

      _broadcastAvailableRooms();
      return roomId;
    } catch (e) {
      debugPrint('Error joining chat room: $e');
      rethrow;
    }
  }

  static Future<void> _joinRemoteRoom(Map<String, dynamic> roomData) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 1000);

      final request = await client.post(roomData['remote_host'], roomData['remote_port'], '/join');
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'room_id': roomData['id'],
        'user_id': _currentUserId,
        'user_name': _currentUserName,
      });

      request.write(body);
      await request.close().timeout(const Duration(milliseconds: 1000));
      client.close();
    } catch (e) {
      debugPrint('Error joining remote room: $e');
    }
  }

  // Send a message
  static Future<void> sendMessage(String roomId, String message) async {
    try {
      _generateUserId();

      if (!_chatRooms.containsKey(roomId)) {
        throw Exception('Phòng chat không tồn tại');
      }

      final messageData = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        'text': message,
        'sender_id': _currentUserId,
        'sender_name': _currentUserName,
        'timestamp': DateTime.now(),
        'type': 'text',
      };

      if (!_roomMessages.containsKey(roomId)) {
        _roomMessages[roomId] = [];
      }
      _roomMessages[roomId]!.add(messageData);

      _chatRooms[roomId]!['last_message'] = message;
      _chatRooms[roomId]!['last_message_at'] = DateTime.now();

      if (_messageStreams.containsKey(roomId)) {
        _messageStreams[roomId]!.add(List.from(_roomMessages[roomId]!));
      }

      _broadcastAvailableRooms();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    if (!_messageStreams.containsKey(roomId)) {
      _messageStreams[roomId] = StreamController<List<Map<String, dynamic>>>.broadcast();
      Future.delayed(Duration.zero, () {
        _messageStreams[roomId]!.add(_roomMessages[roomId] ?? []);
      });
    }
    return _messageStreams[roomId]!.stream;
  }

  // Get room info
  static Future<Map<String, dynamic>?> getRoomInfo(String roomId) async {
    return _chatRooms[roomId];
  }

  // Leave chat room
  static Future<void> leaveChatRoom(String roomId) async {
    try {
      if (_currentUserId == null || !_chatRooms.containsKey(roomId)) return;

      final participants = List<String>.from(_chatRooms[roomId]!['participants'] ?? []);
      participants.remove(_currentUserId);

      if (participants.isEmpty) {
        _chatRooms[roomId]!['is_active'] = false;
        _chatRooms[roomId]!['participant_count'] = 0;
      } else {
        _chatRooms[roomId]!['participants'] = participants;
        _chatRooms[roomId]!['participant_count'] = participants.length;
      }

      _broadcastAvailableRooms();
    } catch (e) {
      debugPrint('Error leaving chat room: $e');
    }
  }

  // No authentication needed
  static Future<void> ensureAuthenticated() async {
    _generateUserId();
    await _startLightweightServer();
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Generate a random room code
  static String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // Get current user ID
  static String? getCurrentUserId() => _currentUserId;

  // Get current user name
  static String? getCurrentUserName() => _currentUserName;

  // Dispose all streams
  static void dispose() {
    for (var controller in _messageStreams.values) {
      controller.close();
    }
    _messageStreams.clear();
    _availableRoomsController.close();
    _discoveryTimer?.cancel();
    _server?.close();
  }
}
