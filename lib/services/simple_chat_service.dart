import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class SimpleChatService {
  // Use default Firestore database
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _currentUserId;
  static String? _currentUserName;

  // Cache for frequently accessed data
  static final Map<String, Map<String, dynamic>> _roomCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Initialize Firestore settings for better performance
  static Future<void> initializeFirestore() async {
    try {
      // Configure Firestore settings for better performance
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      if (kDebugMode) {
        print('Firestore initialized with optimized settings');
      }
    } catch (e) {
      debugPrint('Firestore initialization warning: $e');
      // Continue if settings are already configured
    }
  }

  // Generate a simple user ID without authentication
  static void _generateUserId() {
    if (_currentUserId == null) {
      final random = Random();
      _currentUserId = 'user_${random.nextInt(999999).toString().padLeft(6, '0')}';
      _currentUserName = 'User${random.nextInt(9999).toString().padLeft(4, '0')}';
      if (kDebugMode) {
        print('Generated user ID: $_currentUserId, name: $_currentUserName');
      }
    }
  }

  // Optimized create chat room with minimal operations
  static Future<String> createChatRoom() async {
    try {
      _generateUserId();

      final roomCode = _generateRoomCode();

      // Use batch write for better performance
      final batch = _firestore.batch();
      final chatRoomRef = _firestore.collection('chat_rooms').doc();

      batch.set(chatRoomRef, {
        'created_at': FieldValue.serverTimestamp(),
        'created_by': _currentUserId,
        'participants': [_currentUserId],
        'is_active': true,
        'room_code': roomCode,
        'participant_count': 1,
        'last_activity': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Cache the room data
      _roomCache[chatRoomRef.id] = {
        'room_code': roomCode,
        'is_active': true,
        'participants': [_currentUserId],
      };
      _cacheTimestamps[chatRoomRef.id] = DateTime.now();

      if (kDebugMode) {
        print('Chat room created: ${chatRoomRef.id} with code: $roomCode');
      }

      return chatRoomRef.id;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      rethrow;
    }
  }

  // Optimized join room with caching and indexed queries
  static Future<String> joinChatRoom(String roomCode) async {
    try {
      _generateUserId();

      // Check cache first
      final cachedRoom = _findRoomInCache(roomCode);
      if (cachedRoom != null) {
        return await _joinCachedRoom(cachedRoom['id'], cachedRoom['data']);
      }

      // Use indexed query for better performance
      final querySnapshot = await _firestore
          .collection('chat_rooms')
          .where('room_code', isEqualTo: roomCode.toUpperCase())
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Không tìm thấy phòng chat với mã này');
      }

      final roomDoc = querySnapshot.docs.first;
      final roomId = roomDoc.id;
      final roomData = roomDoc.data();

      // Cache the room
      _roomCache[roomId] = roomData;
      _cacheTimestamps[roomId] = DateTime.now();

      return await _joinCachedRoom(roomId, roomData);
    } catch (e) {
      debugPrint('Error joining chat room: $e');
      rethrow;
    }
  }

  // Helper method to join cached room
  static Future<String> _joinCachedRoom(String roomId, Map<String, dynamic> roomData) async {
    final participants = List<String>.from(roomData['participants'] ?? []);

    if (!participants.contains(_currentUserId)) {
      participants.add(_currentUserId!);

      // Use atomic update for thread safety
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'participants': participants,
        'participant_count': FieldValue.increment(1),
        'last_activity': FieldValue.serverTimestamp(),
      });

      // Update cache
      _roomCache[roomId] = {
        ...roomData,
        'participants': participants,
      };
    }

    return roomId;
  }

  // Find room in cache
  static Map<String, dynamic>? _findRoomInCache(String roomCode) {
    final now = DateTime.now();

    for (final entry in _roomCache.entries) {
      final roomId = entry.key;
      final roomData = entry.value;
      final timestamp = _cacheTimestamps[roomId];

      // Check if cache is still valid
      if (timestamp != null && now.difference(timestamp) < _cacheExpiry) {
        if (roomData['room_code']?.toString().toUpperCase() == roomCode.toUpperCase()) {
          return {'id': roomId, 'data': roomData};
        }
      } else {
        // Remove expired cache
        _roomCache.remove(roomId);
        _cacheTimestamps.remove(roomId);
      }
    }

    return null;
  }

  // Optimized send message with batching
  static Future<void> sendMessage(String roomId, String message) async {
    try {
      _generateUserId();

      final batch = _firestore.batch();

      // Add message
      final messageRef = _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'text': message,
        'sender_id': _currentUserId,
        'sender_name': _currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update room info
      final roomRef = _firestore.collection('chat_rooms').doc(roomId);
      batch.update(roomRef, {
        'last_message': message.length > 100 ? '${message.substring(0, 100)}...' : message,
        'last_message_at': FieldValue.serverTimestamp(),
        'last_activity': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Optimized messages stream with pagination
  static Stream<QuerySnapshot> getMessagesStream(String roomId, {int limit = 50}) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: false);
  }

  // Get more messages for pagination
  static Future<QuerySnapshot> getMoreMessages(String roomId, DocumentSnapshot lastDocument, {int limit = 20}) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDocument)
        .limit(limit)
        .get();
  }

  // Optimized room info with caching
  static Future<Map<String, dynamic>?> getRoomInfo(String roomId) async {
    try {
      // Check cache first
      final now = DateTime.now();
      final cachedData = _roomCache[roomId];
      final timestamp = _cacheTimestamps[roomId];

      if (cachedData != null && timestamp != null && now.difference(timestamp) < _cacheExpiry) {
        return cachedData;
      }

      // Fetch from Firestore
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        final data = doc.data()!;
        _roomCache[roomId] = data;
        _cacheTimestamps[roomId] = now;
        return data;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting room info: $e');
      return null;
    }
  }

  // Optimized leave chat room
  static Future<void> leaveChatRoom(String roomId) async {
    try {
      if (_currentUserId == null) return;

      await _firestore.collection('chat_rooms').doc(roomId).update({
        'participants': FieldValue.arrayRemove([_currentUserId]),
        'participant_count': FieldValue.increment(-1),
        'last_activity': FieldValue.serverTimestamp(),
      });

      // Clean cache
      _roomCache.remove(roomId);
      _cacheTimestamps.remove(roomId);
    } catch (e) {
      debugPrint('Error leaving chat room: $e');
    }
  }

  // Clear expired cache periodically
  static void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _roomCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // No authentication needed - just generate user
  static Future<void> ensureAuthenticated() async {
    _generateUserId();
    await Future.delayed(const Duration(milliseconds: 50)); // Reduced delay
  }

  // Generate a random room code
  static String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // Simplified connection test
  static Future<void> testConnection() async {
    try {
      await _firestore
          .collection('_health')
          .doc('check')
          .get()
          .timeout(const Duration(seconds: 5));
      if (kDebugMode) {
        print('Firestore connection healthy');
      }
    } catch (e) {
      debugPrint('Firestore connection test failed: $e');
      rethrow;
    }
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return _currentUserId;
  }

  // Get current user name
  static String? getCurrentUserName() {
    return _currentUserName;
  }
}
