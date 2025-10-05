# Match Chat System Guide

## Tổng quan

Hệ thống chat đã được chuyển đổi từ database "rizz" sang database **default** và sử dụng **matchId** làm định danh cho các cuộc trò chuyện.

## Cấu trúc Database

### Database: **default** (Firestore default database)

#### Collection: `matches`
- **Document ID**: `{userId1}_{userId2}` (sorted alphabetically)
- **Fields**:
  - `users`: Array[String] - Danh sách 2 user IDs
  - `user1`: String - User ID đầu tiên (sorted)
  - `user2`: String - User ID thứ hai (sorted)
  - `timestamp`: Timestamp - Thời gian tạo match
  - `lastMessage`: String - Tin nhắn cuối cùng
  - `lastMessageAt`: Timestamp - Thời gian tin nhắn cuối
  - `lastMessageBy`: String - User ID người gửi tin nhắn cuối

#### Collection: `messages`
- **Document ID**: Auto-generated
- **Fields**:
  - `matchId`: String - Match ID (format: userId1_userId2)
  - `senderId`: String - User ID người gửi
  - `senderName`: String - Tên người gửi
  - `text`: String - Nội dung tin nhắn
  - `timestamp`: Timestamp - Thời gian gửi
  - `type`: String - Loại tin nhắn (text, image, etc.)
  - `isRead`: Boolean - Đã đọc chưa

#### Collection: `users`
- **Document ID**: User ID
- **Subcollections**:
  - `likes` - Danh sách người đã like
  - `passes` - Danh sách người đã pass

## Services

### 1. MatchChatService (Mới - Khuyến nghị sử dụng)

Service dành cho chat dựa trên match giữa 2 người dùng.

**File**: `lib/services/match_chat_service.dart`

#### Khởi tạo
```dart
await MatchChatService.initializeFirestore();
```

#### Gửi tin nhắn
```dart
await MatchChatService.sendMessage(
  matchId: 'user1_user2',
  senderId: 'user1',
  message: 'Hello!',
  senderName: 'John Doe',
);
```

#### Lắng nghe tin nhắn
```dart
Stream<QuerySnapshot> messagesStream = MatchChatService.getMessagesStream(
  'user1_user2',
  limit: 50,
);
```

#### Đánh dấu đã đọc
```dart
await MatchChatService.markMessagesAsRead('user1_user2', 'user1');
```

#### Đếm tin nhắn chưa đọc
```dart
int unreadCount = await MatchChatService.getUnreadMessageCount(
  'user1_user2',
  'user1',
);
```

#### Lấy danh sách matches
```dart
Stream<QuerySnapshot> matchesStream = MatchChatService.getUserMatchesStream('user1');
```

#### Unmatch (xóa match và tin nhắn)
```dart
await MatchChatService.unmatch('user1_user2');
```

#### Utility methods
```dart
// Tạo match ID từ 2 user IDs
String matchId = MatchChatService.createMatchId('user1', 'user2');

// Lấy ID của người còn lại trong match
String otherId = MatchChatService.getOtherUserId('user1_user2', 'user1');
```

### 2. SimpleChatService (Cũ - Cho random chat)

Service dành cho chat room ngẫu nhiên với room code.

**File**: `lib/services/simple_chat_service.dart`

Đã được cập nhật để sử dụng database **default**.

## Cách sử dụng trong Profile Provider

Khi 2 người like nhau, match sẽ tự động được tạo:

```dart
// Trong ProfileProvider.likeProfile()
if (isMutual) {
  final sortedUsers = [_currentUserId!, profileId]..sort();
  final matchId = '${sortedUsers[0]}_${sortedUsers[1]}';
  
  // Tạo match document
  final matchRef = _firestore.collection('matches').doc(matchId);
  batch.set(matchRef, {
    'users': sortedUsers,
    'timestamp': FieldValue.serverTimestamp(),
    'user1': sortedUsers[0],
    'user2': sortedUsers[1],
  });
}
```

## Migration từ database "rizz"

Tất cả các file đã được cập nhật để sử dụng database **default**:

1. ✅ **ProfileProvider** - Sử dụng `FirebaseFirestore.instance`
2. ✅ **SimpleChatService** - Sử dụng `FirebaseFirestore.instance`
3. ✅ **MatchChatService** - Service mới cho match-based chat

## Firestore Indexes (Cần tạo)

Tạo các indexes sau trong Firebase Console:

### Collection: `messages`
- **Composite Index 1**:
  - `matchId` (Ascending)
  - `timestamp` (Descending)

- **Composite Index 2**:
  - `matchId` (Ascending)
  - `senderId` (Ascending)
  - `isRead` (Ascending)

### Collection: `matches`
- **Composite Index**:
  - `users` (Array)
  - `lastMessageAt` (Descending)

## Ưu điểm của cấu trúc mới

1. **Đơn giản hơn**: Chỉ sử dụng 1 database (default)
2. **Hiệu quả hơn**: Tin nhắn được lưu trong collection riêng, dễ query
3. **Scalable**: Dễ mở rộng với nhiều tính năng (typing indicator, read receipts, etc.)
4. **Organized**: Match ID rõ ràng, dễ quản lý
5. **Cache friendly**: Có built-in caching mechanism

## Testing

Kiểm tra kết nối:
```dart
await MatchChatService.testConnection();
```

Xóa cache hết hạn:
```dart
MatchChatService.clearExpiredCache();
```

## Lưu ý

- Match ID luôn được tạo bằng cách sắp xếp 2 user IDs theo thứ tự alphabet
- Firestore Settings chỉ có thể được set 1 lần, sau đó sẽ throw warning (normal behavior)
- Tin nhắn được query theo `matchId` để đảm bảo performance
- Cache có thời hạn 5 phút để giảm số lần query Firestore

