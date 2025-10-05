c# Hướng dẫn sử dụng Tab Chat với Match System

## Tổng quan

Tab Chat đã được chuyển đổi để hiển thị danh sách các cuộc trò chuyện từ matches. Khi người dùng bấm vào một cuộc trò chuyện, họ sẽ được chuyển đến trang chi tiết để xem và gửi tin nhắn.

## Cấu trúc

### 1. Tab Chat (`lib/pages/tabs/chat.dart`)
Hiển thị danh sách các matches với:
- **Avatar** người dùng
- **Tên** người dùng
- **Tin nhắn cuối cùng** (preview)
- **Thời gian** tin nhắn cuối
- **Badge đỏ** hiển thị số tin nhắn chưa đọc
- **Sắp xếp** theo thời gian tin nhắn mới nhất

### 2. Trang Chi tiết Chat (`lib/pages/match_chat_detail_page.dart`)
Hiển thị tin nhắn và cho phép gửi tin nhắn với:
- **Header** hiển thị avatar và tên người chat
- **Danh sách tin nhắn** (realtime update)
- **Message bubbles** với màu khác nhau cho người gửi/nhận
- **Input box** để nhập và gửi tin nhắn
- **Menu** để unmatch (hủy kết nối)
- **Auto mark as read** khi mở chat

## Tính năng

### ✅ Đã hoàn thành

1. **Danh sách matches realtime**
   - Stream từ Firestore cập nhật tức thì
   - Hiển thị thông tin người dùng từ collection `users`
   - Sắp xếp theo `lastMessageAt` (tin nhắn mới nhất lên đầu)

2. **Tin nhắn chưa đọc**
   - Đếm số tin nhắn chưa đọc cho mỗi match
   - Badge đỏ hiển thị số lượng (hoặc "9+" nếu >9)
   - Font đậm cho tên và preview khi có tin nhắn chưa đọc

3. **Trang chi tiết chat**
   - Hiển thị tin nhắn realtime
   - Gửi tin nhắn với animation mượt
   - Auto scroll xuống tin nhắn mới
   - Format thời gian thông minh (HH:mm, Hôm qua, T2-T7, DD/MM/YYYY)

4. **Đánh dấu đã đọc**
   - Tự động đánh dấu tin nhắn đã đọc khi mở chat
   - Chỉ đánh dấu tin nhắn của người khác

5. **Unmatch**
   - Hủy kết nối với người dùng
   - Xóa tất cả tin nhắn
   - Có dialog xác nhận

## Flow hoạt động

```
1. User A likes User B
   ↓
2. User B likes User A back
   ↓
3. Match được tạo trong collection `matches`
   - matchId: "userA_userB" (sorted alphabetically)
   - users: ["userA", "userB"]
   ↓
4. Match xuất hiện trong Tab Chat của cả 2 người
   ↓
5. User bấm vào match → Mở trang chi tiết
   ↓
6. Gửi tin nhắn → Lưu vào collection `messages`
   - matchId: "userA_userB"
   - senderId, text, timestamp, isRead
   ↓
7. Match document được update với lastMessage, lastMessageAt
   ↓
8. Tin nhắn hiển thị realtime cho cả 2 người
```

## Database Structure

### Collection: `matches`
```
matches/{matchId}
  ├── users: ["userId1", "userId2"]
  ├── user1: "userId1"
  ├── user2: "userId2"
  ├── timestamp: Timestamp
  ├── lastMessage: "Hello world"
  ├── lastMessageAt: Timestamp
  └── lastMessageBy: "userId1"
```

### Collection: `messages`
```
messages/{messageId}
  ├── matchId: "userId1_userId2"
  ├── senderId: "userId1"
  ├── senderName: "John Doe"
  ├── text: "Hello world"
  ├── timestamp: Timestamp
  ├── type: "text"
  └── isRead: false
```

## UI Components

### Chat Tab - Match Item
```dart
ListTile(
  leading: Avatar + Badge (unread count)
  title: User name (bold if unread)
  subtitle: Last message preview
  trailing: Timestamp
  onTap: Navigate to chat detail
)
```

### Chat Detail - Message Bubble
```dart
Container(
  // Pink background for sent messages
  // Grey background for received messages
  // Rounded corners
  // Timestamp below
)
```

## Code Examples

### Lấy danh sách matches
```dart
StreamBuilder<QuerySnapshot>(
  stream: MatchChatService.getUserMatchesStream(currentUserId),
  builder: (context, snapshot) {
    // Build list of matches
  },
)
```

### Hiển thị tin nhắn
```dart
StreamBuilder<QuerySnapshot>(
  stream: MatchChatService.getMessagesStream(matchId),
  builder: (context, snapshot) {
    // Build list of messages
  },
)
```

### Gửi tin nhắn
```dart
await MatchChatService.sendMessage(
  matchId: matchId,
  senderId: currentUserId,
  message: text,
);
```

### Đánh dấu đã đọc
```dart
await MatchChatService.markMessagesAsRead(matchId, currentUserId);
```

## Firestore Indexes Required

Tạo các indexes sau trong Firebase Console:

### 1. Messages Collection
```
Collection: messages
Fields:
  - matchId (Ascending)
  - timestamp (Descending)
```

### 2. Messages Collection (for unread count)
```
Collection: messages
Fields:
  - matchId (Ascending)
  - senderId (Ascending)
  - isRead (Ascending)
```

### 3. Matches Collection
```
Collection: matches
Fields:
  - users (Array)
  - lastMessageAt (Descending)
```

## Firestore Security Rules

Thêm rules sau vào Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Matches - chỉ 2 người trong match được đọc/ghi
    match /matches/{matchId} {
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.users;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       request.auth.uid in resource.data.users;
      allow delete: if request.auth != null && 
                       request.auth.uid in resource.data.users;
    }
    
    // Messages - chỉ 2 người trong match được đọc/ghi
    match /messages/{messageId} {
      allow read: if request.auth != null && 
                     request.auth.uid in getMatchUsers(resource.data.matchId);
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.senderId;
      allow update: if request.auth != null && 
                       request.auth.uid in getMatchUsers(resource.data.matchId);
      allow delete: if request.auth != null && 
                       (request.auth.uid == resource.data.senderId || 
                        request.auth.uid in getMatchUsers(resource.data.matchId));
    }
    
    // Helper function
    function getMatchUsers(matchId) {
      return get(/databases/$(database)/documents/matches/$(matchId)).data.users;
    }
  }
}
```

## Testing Checklist

- [ ] Tab Chat hiển thị danh sách matches
- [ ] Bấm vào match mở được trang chi tiết
- [ ] Gửi tin nhắn thành công
- [ ] Tin nhắn hiển thị realtime
- [ ] Badge số tin nhắn chưa đọc hiển thị đúng
- [ ] Đánh dấu đã đọc khi mở chat
- [ ] Unmatch xóa được match và tin nhắn
- [ ] UI responsive trên nhiều màn hình
- [ ] Scroll mượt mà
- [ ] Keyboard không che input box

## Troubleshooting

### Lỗi: "Missing or insufficient permissions"
→ Kiểm tra Firestore Security Rules
→ Đảm bảo user đã đăng nhập

### Lỗi: "Index not found"
→ Tạo các composite indexes trong Firebase Console
→ Click vào link trong error message

### Tin nhắn không hiển thị realtime
→ Kiểm tra kết nối internet
→ Kiểm tra Firestore rules
→ Restart app

### Badge số tin nhắn không chính xác
→ Clear app cache
→ Kiểm tra query trong `getUnreadMessageCount`

## Future Enhancements

- [ ] Typing indicator (đang nhập...)
- [ ] Online/offline status
- [ ] Gửi hình ảnh
- [ ] Gửi voice message
- [ ] Delete message
- [ ] Edit message
- [ ] Message reactions (emoji)
- [ ] Group chat
- [ ] Search messages
- [ ] Push notifications

## Performance Tips

1. **Pagination**: Load tin nhắn theo batch (đã implement trong service)
2. **Cache**: Sử dụng cache để giảm query (đã có trong MatchChatService)
3. **Image optimization**: Compress avatar trước khi upload
4. **Lazy loading**: Chỉ load user info khi cần
5. **Debounce**: Giới hạn tần suất gửi tin nhắn

## Notes

- MatchId luôn được tạo theo format: `userId1_userId2` (sorted alphabetically)
- Firestore Settings chỉ set 1 lần (ở SimpleChatService.initializeFirestore)
- Cache có thời hạn 5 phút
- Message bubbles reverse order (tin nhắn mới nhất ở dưới cùng)

