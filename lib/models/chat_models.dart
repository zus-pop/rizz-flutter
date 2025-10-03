import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho tin nhắn chat trong Firebase
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final String chatRoomId;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.chatRoomId,
  });

  /// Tạo ChatMessage từ Firebase DocumentSnapshot
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      chatRoomId: data['chatRoomId'] ?? '',
    );
  }

  /// Chuyển ChatMessage thành Map để lưu vào Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': Timestamp.fromDate(timestamp),
      'chatRoomId': chatRoomId,
    };
  }

  /// Copy message với các thuộc tính mới
  ChatMessage copyWith({
    String? id,
    String? text,
    String? senderId,
    String? senderName,
    DateTime? timestamp,
    String? chatRoomId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.text == text &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.timestamp == timestamp &&
        other.chatRoomId == chatRoomId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        senderId.hashCode ^
        senderName.hashCode ^
        timestamp.hashCode ^
        chatRoomId.hashCode;
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, text: $text, senderId: $senderId, senderName: $senderName, timestamp: $timestamp, chatRoomId: $chatRoomId)';
  }
}

/// Model cho phòng chat trong Firebase
class ChatRoom {
  final String id;
  final String roomName;
  final String description;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String createdBy;
  final DateTime createdAt;
  final bool isPublic;
  final int maxParticipants;

  ChatRoom({
    required this.id,
    required this.roomName,
    this.description = '',
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdBy,
    required this.createdAt,
    this.isPublic = true,
    this.maxParticipants = 100,
  });

  /// Tạo ChatRoom từ Firebase DocumentSnapshot
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      roomName: data['roomName'] ?? '',
      description: data['description'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['isPublic'] ?? true,
      maxParticipants: data['maxParticipants'] ?? 100,
    );
  }

  /// Chuyển ChatRoom thành Map để lưu vào Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'roomName': roomName,
      'description': description,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null 
          ? Timestamp.fromDate(lastMessageTime!) 
          : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublic': isPublic,
      'maxParticipants': maxParticipants,
    };
  }

  /// Copy room với các thuộc tính mới
  ChatRoom copyWith({
    String? id,
    String? roomName,
    String? description,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? createdBy,
    DateTime? createdAt,
    bool? isPublic,
    int? maxParticipants,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }

  /// Kiểm tra xem user có trong phòng chat không
  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  /// Kiểm tra xem phòng chat có đầy không
  bool get isFull {
    return participants.length >= maxParticipants;
  }

  /// Lấy số lượng thành viên hiện tại
  int get participantCount {
    return participants.length;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom &&
        other.id == id &&
        other.roomName == roomName &&
        other.description == description &&
        other.participants.length == participants.length &&
        other.lastMessage == lastMessage &&
        other.lastMessageTime == lastMessageTime &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.isPublic == isPublic &&
        other.maxParticipants == maxParticipants;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        roomName.hashCode ^
        description.hashCode ^
        participants.hashCode ^
        lastMessage.hashCode ^
        lastMessageTime.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        isPublic.hashCode ^
        maxParticipants.hashCode;
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, roomName: $roomName, participants: ${participants.length}, isPublic: $isPublic)';
  }
}

/// Enum cho trạng thái của tin nhắn
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Model cho typing indicator
class TypingIndicator {
  final String userId;
  final String userName;
  final DateTime timestamp;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory TypingIndicator.fromFirestore(Map<String, dynamic> data) {
    return TypingIndicator(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Kiểm tra xem typing indicator có hết hạn không (>3 giây)
  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > 3;
  }
}