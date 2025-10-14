# Chat Widgets

Thư mục này chứa các widget được tái sử dụng cho tính năng chat.

## MessageBubble

Widget hiển thị tin nhắn với các tính năng:

### ✨ Tính năng chính:

1. **Swipe để xem giờ gửi**:
   - 👉 Tin nhắn của tôi: **Vuốt qua trái** (endToStart)
   - 👈 Tin nhắn người khác: **Vuốt qua phải** (startToEnd)
   - Giờ gửi hiển thị tự động sau khi vuốt và ẩn sau 2 giây

2. **Thiết kế nổi bật**:
   - Tin nhắn của tôi: Màu primary với text màu trắng
   - Tin nhắn người khác: **Nền trắng với shadow** để nổi bật hơn
   - Avatar hiển thị cho tin nhắn người khác

3. **Format thời gian thông minh**:
   - Hôm nay: chỉ hiển thị giờ (VD: "14:30")
   - Hôm qua: "Hôm qua 14:30"
   - Trong tuần: "T3 14:30"
   - Cũ hơn: "15/10/2024 14:30"

### 📝 Cách sử dụng:

```dart
MessageBubble(
  text: "Xin chào!",
  isMe: false,
  timestamp: Timestamp.now(),
  showAvatar: true,
  avatarUrl: "https://example.com/avatar.jpg",
  userName: "Nguyễn Văn A",
)
```

### 🎨 Style:

- **Tin nhắn của tôi**:
  - Background: `context.primary`
  - Text: `context.onPrimary` (trắng)
  - Border radius: Bo góc phải dưới nhỏ (4px)

- **Tin nhắn người khác**:
  - Background: `Colors.white`
  - Text: `Colors.grey[900]`
  - Border radius: Bo góc trái dưới nhỏ (4px)
  - Shadow: `BoxShadow` với alpha 0.08

## Các widget khác:

- **AISuggestionsPanel**: Panel gợi ý AI cho premium users
- **MessageInputBar**: Thanh nhập tin nhắn với nút AI và gửi
- **MessagesListView**: ListView hiển thị danh sách tin nhắn
- **ChatAppBar**: AppBar tùy chỉnh cho màn hình chat
