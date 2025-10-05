import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for match-based chat using default Firestore database
/// Uses matchId from matches collection as the chat identifier
class MatchChatService {
  // Use default Firestore database
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for frequently accessed data
  static final Map<String, Map<String, dynamic>> _matchCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Initialize Firestore settings for better performance
  static Future<void> initializeFirestore() async {
    try {
      // Configure Firestore settings for better performance
      final settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _firestore.settings = settings;

      if (kDebugMode) {
        print('Match Chat Firestore initialized with optimized settings');
      }
    } catch (e) {
      debugPrint('Firestore initialization warning: $e');
      // Continue if settings are already configured
    }
  }

  /// Send a message in a match chat
  ///
  /// [matchId] - The match ID (format: userId1_userId2, sorted alphabetically)
  /// [senderId] - The user ID of the message sender
  /// [message] - The message text
  /// [senderName] - Optional sender name for display
  static Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String message,
    String? senderName,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add message to messages collection
      final messageRef = _firestore.collection('messages').doc();

      batch.set(messageRef, {
        'matchId': matchId,
        'senderId': senderId,
        'senderName': senderName,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false,
      });

      // Update match document with last message info
      final matchRef = _firestore.collection('matches').doc(matchId);
      batch.update(matchRef, {
        'lastMessage': message.length > 100
            ? '${message.substring(0, 100)}...'
            : message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageBy': senderId,
      });

      await batch.commit();

      if (kDebugMode) {
        print('Message sent in match: $matchId');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages stream for a specific match
  ///
  /// [matchId] - The match ID to get messages for
  /// [limit] - Maximum number of messages to fetch (default: 50)
  static Stream<QuerySnapshot> getMessagesStream(
    String matchId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('messages')
        .where('matchId', isEqualTo: matchId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: false);
  }

  /// Get more messages for pagination
  ///
  /// [matchId] - The match ID
  /// [lastDocument] - The last document from previous query
  /// [limit] - Number of messages to fetch (default: 20)
  static Future<QuerySnapshot> getMoreMessages(
    String matchId,
    DocumentSnapshot lastDocument, {
    int limit = 20,
  }) {
    return _firestore
        .collection('messages')
        .where('matchId', isEqualTo: matchId)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDocument)
        .limit(limit)
        .get();
  }

  /// Get match info with caching
  ///
  /// [matchId] - The match ID
  static Future<Map<String, dynamic>?> getMatchInfo(String matchId) async {
    try {
      // Check cache first
      final now = DateTime.now();
      final cachedData = _matchCache[matchId];
      final timestamp = _cacheTimestamps[matchId];

      if (cachedData != null &&
          timestamp != null &&
          now.difference(timestamp) < _cacheExpiry) {
        return cachedData;
      }

      // Fetch from Firestore
      final doc = await _firestore
          .collection('matches')
          .doc(matchId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists) {
        final data = doc.data()!;
        _matchCache[matchId] = data;
        _cacheTimestamps[matchId] = now;
        return data;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting match info: $e');
      return null;
    }
  }

  /// Mark messages as read
  ///
  /// [matchId] - The match ID
  /// [userId] - The user ID who is reading the messages
  static Future<void> markMessagesAsRead(
    String matchId,
    String userId,
  ) async {
    try {
      // Get unread messages sent by the other user
      final unreadMessages = await _firestore
          .collection('messages')
          .where('matchId', isEqualTo: matchId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      // Batch update to mark as read
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (kDebugMode) {
        print('Marked ${unreadMessages.docs.length} messages as read');
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Get unread message count for a match
  ///
  /// [matchId] - The match ID
  /// [userId] - The user ID to check unread messages for
  static Future<int> getUnreadMessageCount(
    String matchId,
    String userId,
  ) async {
    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('matchId', isEqualTo: matchId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return unreadMessages.count ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get all matches for a user
  ///
  /// [userId] - The user ID
  static Stream<QuerySnapshot> getUserMatchesStream(String userId) {
    debugPrint('🔍 MatchChatService.getUserMatchesStream()');
    debugPrint('   User ID: $userId');
    debugPrint('   Query: matches.where("users", arrayContains: "$userId")');

    try {
      // Query without orderBy to get all matches, including those without lastMessageAt
      // We'll sort in the client side if needed
      final stream = _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .snapshots();

      debugPrint('   ✅ Stream created successfully (without orderBy for compatibility)');
      return stream;
    } catch (e) {
      debugPrint('   ❌ Error creating stream: $e');
      rethrow;
    }
  }

  /// Delete a message
  ///
  /// [messageId] - The message document ID
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();

      if (kDebugMode) {
        print('Message deleted: $messageId');
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Unmatch - delete the match and all associated messages
  ///
  /// [matchId] - The match ID to delete
  static Future<void> unmatch(String matchId) async {
    try {
      final batch = _firestore.batch();

      // Delete match document
      final matchRef = _firestore.collection('matches').doc(matchId);
      batch.delete(matchRef);

      // Get all messages for this match
      final messages = await _firestore
          .collection('messages')
          .where('matchId', isEqualTo: matchId)
          .get();

      // Delete all messages (max 500 per batch)
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Clear cache
      _matchCache.remove(matchId);
      _cacheTimestamps.remove(matchId);

      if (kDebugMode) {
        print('Unmatched and deleted ${messages.docs.length} messages');
      }
    } catch (e) {
      debugPrint('Error unmatching: $e');
      rethrow;
    }
  }

  /// Clear expired cache periodically
  static void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _matchCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      print('Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  /// Test Firestore connection
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

  /// Create match ID from two user IDs (sorted alphabetically)
  ///
  /// [userId1] - First user ID
  /// [userId2] - Second user ID
  static String createMatchId(String userId1, String userId2) {
    final sortedUsers = [userId1, userId2]..sort();
    return '${sortedUsers[0]}_${sortedUsers[1]}';
  }

  /// Get the other user ID from a match
  ///
  /// [matchId] - The match ID
  /// [currentUserId] - The current user ID
  static String getOtherUserId(String matchId, String currentUserId) {
    final users = matchId.split('_');
    return users[0] == currentUserId ? users[1] : users[0];
  }
}
