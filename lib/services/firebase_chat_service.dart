import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or join a chat room
  static Future<String> createChatRoom() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a new chat room
      final chatRoom = await _firestore.collection('chat_rooms').add({
        'created_at': FieldValue.serverTimestamp(),
        'created_by': user.uid,
        'participants': [user.uid],
        'is_active': true,
        'room_code': _generateRoomCode(),
      });

      debugPrint('Chat room created: ${chatRoom.id}');
      return chatRoom.id;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      rethrow;
    }
  }

  // Join a chat room using room code
  static Future<String> joinChatRoom(String roomCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Find chat room by code
      final querySnapshot = await _firestore
          .collection('chat_rooms')
          .where('room_code', isEqualTo: roomCode)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Không tìm thấy phòng chat với mã này');
      }

      final roomDoc = querySnapshot.docs.first;
      final roomId = roomDoc.id;
      final roomData = roomDoc.data();

      // Add current user to participants if not already present
      final participants = List<String>.from(roomData['participants'] ?? []);
      if (!participants.contains(user.uid)) {
        participants.add(user.uid);
        await _firestore.collection('chat_rooms').doc(roomId).update({
          'participants': participants,
        });
      }

      debugPrint('Joined chat room: $roomId');
      return roomId;
    } catch (e) {
      debugPrint('Error joining chat room: $e');
      rethrow;
    }
  }

  // Send a message
  static Future<void> sendMessage(String roomId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .add({
        'text': message,
        'sender_id': user.uid,
        'sender_name': user.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update room's last activity
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'last_message': message,
        'last_message_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream
  static Stream<QuerySnapshot> getMessagesStream(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get room info
  static Future<Map<String, dynamic>?> getRoomInfo(String roomId) async {
    try {
      final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting room info: $e');
      return null;
    }
  }

  // Leave chat room
  static Future<void> leaveChatRoom(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final roomDoc = await _firestore.collection('chat_rooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final roomData = roomDoc.data()!;
      final participants = List<String>.from(roomData['participants'] ?? []);

      participants.remove(user.uid);

      if (participants.isEmpty) {
        // If no participants left, deactivate room
        await _firestore.collection('chat_rooms').doc(roomId).update({
          'is_active': false,
          'participants': participants,
        });
      } else {
        await _firestore.collection('chat_rooms').doc(roomId).update({
          'participants': participants,
        });
      }
    } catch (e) {
      debugPrint('Error leaving chat room: $e');
    }
  }

  // Sign in anonymously if not authenticated
  static Future<void> ensureAuthenticated() async {
    try {
      if (_auth.currentUser == null) {
        // Try anonymous authentication first
        try {
          await _auth.signInAnonymously();
          debugPrint('Signed in anonymously: ${_auth.currentUser?.uid}');
        } catch (e) {
          debugPrint('Anonymous sign-in failed: $e');
          // If anonymous auth fails, create a temporary user ID
          // This is a fallback for when Firebase project doesn't allow anonymous auth
          throw Exception('Firebase chưa được cấu hình đúng. Vui lòng kiểm tra cài đặt Firebase Authentication và bật Anonymous Authentication trong Firebase Console.');
        }
      }
    } catch (e) {
      debugPrint('Error in ensureAuthenticated: $e');
      rethrow;
    }
  }

  // Generate a random room code
  static String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(6, (index) => chars.codeUnitAt(
        (DateTime.now().millisecondsSinceEpoch + index) % chars.length
      ))
    );
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
