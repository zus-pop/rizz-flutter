# 🔍 Hướng Dẫn Debug Chức Năng Chat

## ⚠️ Vấn đề: Không gửi được tin nhắn

### 📋 Checklist để kiểm tra:

---

## 1️⃣ **Kiểm tra Firebase Console**

### Bước 1: Vào Firebase Console
```
https://console.firebase.google.com/
```

### Bước 2: Chọn Project `rizz-7e0b8`

### Bước 3: Vào Firestore Database
- Sidebar → **Firestore Database**
- Kiểm tra xem có collection `messages` chưa?
- Kiểm tra xem có collection `matches` chưa?

### ✅ Nếu chưa có collections:
**Firestore sẽ TỰ ĐỘNG tạo** khi bạn gửi tin nhắn đầu tiên!

---

## 2️⃣ **Kiểm tra Firestore Rules**

### Vào: Firestore Database → Rules

### Đảm bảo rules cho phép ghi:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow read/write to authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Or specific rules:
    match /matches/{matchId} {
      allow read, write: if request.auth != null 
        && request.auth.uid in resource.data.users;
    }
    
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Nhấn **"Publish"** để áp dụng rules!

---

## 3️⃣ **Chạy App và Xem Console Logs**

### Khi bạn nhấn nút Send, console sẽ hiển thị:

```
═══════════════════════════════════════
📤 SENDING MESSAGE
═══════════════════════════════════════
Match ID: 2NjOtUu2KgZYdU08zBog_stjRitBVJvBYYIa3E2UH
Current User ID: stjRitBVJvBYYIa3E2UH
Message: Xin chào!
Message Length: 9
Is Empty: false
Is Sending: false
🔄 Calling MatchChatService.sendMessage...

🔷🔷🔷 MatchChatService.sendMessage() 🔷🔷🔷
📥 Input Parameters:
   - matchId: 2NjOtUu2KgZYdU08zBog_stjRitBVJvBYYIa3E2UH
   - senderId: stjRitBVJvBYYIa3E2UH
   - message: Xin chào!
   - senderName: null

📝 Creating message document:
   - Collection: messages
   - Document ID: abc123xyz
   - Message data: {
       matchId: 2NjOtUu2KgZYdU08zBog_stjRitBVJvBYYIa3E2UH,
       senderId: stjRitBVJvBYYIa3E2UH,
       text: Xin chào!,
       type: text,
       isRead: false
     }
✅ Message batch.set() added

📝 Updating match document:
   - Collection: matches
   - Document ID: 2NjOtUu2KgZYdU08zBog_stjRitBVJvBYYIa3E2UH
   - Update data: {
       lastMessage: Xin chào!,
       lastMessageBy: stjRitBVJvBYYIa3E2UH
     }
✅ Match batch.update() added

🔄 Committing batch to Firestore...
✅✅✅ BATCH COMMITTED SUCCESSFULLY! ✅✅✅
🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷🔷

✅ Message sent successfully!
═══════════════════════════════════════
```

---

## 4️⃣ **Các Lỗi Thường Gặp**

### ❌ Lỗi 1: "Chưa đăng nhập"
```
❌ BLOCKED: currentUserId=null
```
**Giải pháp:**
- Đảm bảo đã đăng nhập Firebase Auth
- Kiểm tra `FirebaseAuth.instance.currentUser`

---

### ❌ Lỗi 2: "PERMISSION_DENIED"
```
❌ ERROR IN sendMessage()
Error: PERMISSION_DENIED
```
**Giải pháp:**
1. Vào Firebase Console → Firestore Database → Rules
2. Thay đổi rules thành:
   ```javascript
   allow read, write: if request.auth != null;
   ```
3. Nhấn **"Publish"**

---

### ❌ Lỗi 3: "Collection messages not found"
**Đây KHÔNG phải lỗi!**
- Firestore sẽ **TỰ ĐỘNG tạo** collection `messages` khi gửi tin nhắn đầu tiên
- Không cần tạo thủ công

---

### ❌ Lỗi 4: Nút Send không hoạt động
**Kiểm tra:**
1. Có nhập text vào TextField chưa?
2. Console có in ra `📤 SENDING MESSAGE` không?
3. Nếu không → Kiểm tra `onTap` của InkWell

---

## 5️⃣ **Test Từng Bước**

### Bước 1: Mở Chat Detail Page
```
👉 Vào Tab Chat → Chọn 1 match
```

### Bước 2: Nhập tin nhắn
```
👉 Nhập "Test message" vào TextField
```

### Bước 3: Nhấn nút Send
```
👉 Nhấn nút Send màu hồng
```

### Bước 4: Xem Console
```
👉 Tìm logs có emoji 📤 và 🔷
```

### Bước 5: Kiểm tra Firebase Console
```
👉 Vào Firestore → Collection messages
👉 Xem có document mới không?
```

---

## 6️⃣ **Tạo Collection Thủ Công (Nếu Cần)**

### Trong Firebase Console:

1. **Vào Firestore Database**
2. **Click "Start collection"**
3. **Collection ID**: `messages`
4. **Document ID**: `test-message`
5. **Fields**:
   ```
   matchId: "test_match"
   senderId: "test_user"
   text: "Test message"
   timestamp: Timestamp.now()
   type: "text"
   isRead: false
   ```
6. **Click "Save"**

---

## 7️⃣ **Kiểm tra Firestore Indexes**

### Nếu gặp lỗi về indexes:

1. Console sẽ hiển thị link tạo index
2. Click vào link đó
3. Chờ vài phút để index được tạo
4. Thử lại

---

## 8️⃣ **Test Connection**

### Thêm code test vào app:

```dart
// In initState() of chat detail page
void initState() {
  super.initState();
  _testFirestoreConnection();
}

Future<void> _testFirestoreConnection() async {
  try {
    debugPrint('🧪 Testing Firestore connection...');
    await FirebaseFirestore.instance.collection('_test').doc('test').set({
      'timestamp': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Firestore connection OK!');
    
    // Delete test doc
    await FirebaseFirestore.instance.collection('_test').doc('test').delete();
  } catch (e) {
    debugPrint('❌ Firestore connection FAILED: $e');
  }
}
```

---

## 9️⃣ **Các Logs Quan Trọng**

### ✅ Logs thành công:
```
📤 SENDING MESSAGE
🔄 Calling MatchChatService.sendMessage...
🔷🔷🔷 MatchChatService.sendMessage()
✅✅✅ BATCH COMMITTED SUCCESSFULLY!
✅ Message sent successfully!
```

### ❌ Logs lỗi:
```
❌ BLOCKED: message.isEmpty=true
❌ ERROR IN sendMessage()
❌ Error Type: FirebaseException
❌ Error Message: PERMISSION_DENIED
```

---

## 🔟 **Giải pháp Nhanh**

### Nếu vẫn không gửi được:

1. **Restart app**
2. **Check internet connection**
3. **Check Firebase Rules**
4. **Check user đã đăng nhập chưa**
5. **Xem console logs**

---

## 📞 Support

Nếu vẫn gặp vấn đề, hãy:
1. Copy toàn bộ console logs
2. Screenshot Firebase Console
3. Gửi cho developer

---

## ✅ Tổng Kết

Khi chạy app và nhấn Send:
- ✅ Console sẽ in ra **NHIỀU LOGS** chi tiết
- ✅ Firestore sẽ **TỰ ĐỘNG tạo** collection `messages`
- ✅ Tin nhắn sẽ xuất hiện **REAL-TIME**
- ✅ Nếu lỗi → Console sẽ in ra **ERROR MESSAGE** rõ ràng

**Happy Debugging! 🐛🔧**

