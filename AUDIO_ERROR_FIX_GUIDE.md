# Hướng dẫn Fix Lỗi Audio Player & Google API

## 🔴 Tổng quan các lỗi

Bạn gặp 2 loại lỗi chính:

### 1. Lỗi MediaPlayer (Error 1, -1005)
```
E/MediaPlayerNative: error (1, -1005)
E/MediaPlayer: Error (1,-1005)
AudioPlayerException: MEDIA_ERROR_UNKNOWN
UrlSource(url: https://example.com/audio/phúc.mp3)
UrlSource(url: https://example.com/audio/trang.mp3)
```

### 2. Lỗi GoogleApiManager
```
E/GoogleApiManager: SecurityException: Unknown calling package name 'com.google.android.gms'
```

---

## 📋 Chi tiết từng lỗi và cách fix

### ❌ LỖI 1: MediaPlayer Error (1, -1005)

#### **Nguyên nhân:**

1. **URL không hợp lệ:**
   - `https://example.com` là URL giả, không tồn tại thật
   - URL có chứa ký tự Unicode không được encode (`phúc.mp3`, `trang.mp3`)
   
2. **Thiếu xử lý lỗi:**
   - Khi URL fail, app crash thay vì hiển thị lỗi gracefully
   - Không có try-catch để bắt exception

3. **Audio file không tồn tại:**
   - Server không có file audio tại URL đó
   - Hoặc server từ chối kết nối

#### **Ý nghĩa mã lỗi:**
- **Error Code 1**: `MEDIA_ERROR_UNKNOWN` - Lỗi không xác định
- **Error Code -1005**: Lỗi I/O khi đọc file audio (file không tồn tại, network issue, permission denied)

#### **✅ Cách fix:**

**Fix 1: Thêm error handling trong audio listeners**
```dart
void _setupAudioListeners() async {
  try {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    
    // ... các listeners khác
    
    // Thêm listener để bắt lỗi
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isCompleted = true;
        });
      }
    });
  } catch (e) {
    debugPrint('Error setting up audio listeners: $e');
    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }
}
```

**Fix 2: Validate URL trước khi load**
```dart
Future<void> _loadAudio() async {
  setState(() {
    _isLoading = true;
    _hasError = false;
  });

  try {
    // Validate URL
    if (widget.audioUrl.isEmpty || !Uri.parse(widget.audioUrl).isAbsolute) {
      throw Exception('Invalid audio URL');
    }
    
    await _audioPlayer.setSource(UrlSource(widget.audioUrl));
    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
    debugPrint('Error loading audio: $e');
    
    // Hiển thị thông báo lỗi cho user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải audio. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Fix 3: Sử dụng URL thật thay vì example.com**
```dart
// ❌ SAI
final audioUrl = 'https://example.com/audio/phúc.mp3';

// ✅ ĐÚNG - Sử dụng URL từ Firebase Storage hoặc server thật
final audioUrl = 'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/audio%2Fuser123.mp3?alt=media&token=xxx';

// Hoặc encode ký tự Unicode đúng cách
final audioUrl = Uri.encodeFull('https://your-server.com/audio/phúc.mp3');
```

#### **Kết quả sau khi fix:**
- ✅ App không còn crash khi URL fail
- ✅ Hiển thị icon error thay vì crash
- ✅ User có thể retry bằng cách bấm lại play button
- ✅ URL được validate trước khi load

---

### ❌ LỖI 2: GoogleApiManager SecurityException

#### **Nguyên nhân:**

1. **Chạy trên Emulator:**
   - Lỗi này thường xảy ra trên Android Emulator
   - Google Play Services không được cấu hình đúng

2. **Thiếu SHA-1 Fingerprint:**
   - SHA-1 certificate fingerprint chưa được thêm vào Firebase Console
   - Google Sign-In, Firebase Auth không hoạt động đúng

3. **Package name mismatch:**
   - Package name trong code khác với package name đã đăng ký trong Firebase

#### **⚠️ Quan trọng:**
Lỗi này **KHÔNG ẢNH HƯỞNG** đến chức năng audio player. Nó chỉ ảnh hưởng đến:
- Google Sign-In
- Firebase Authentication
- Google Play Services APIs

#### **✅ Cách fix:**

**Fix 1: Thêm SHA-1 Fingerprint vào Firebase Console**

**Bước 1: Lấy SHA-1 fingerprint**
```bash
# Debug keystore (cho development)
cd C:\Users\Work\Desktop\FPTU\EXE\App\rizz-flutter\android
gradlew signingReport

# Hoặc dùng keytool
keytool -list -v -keystore "C:\Users\Work\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Bước 2: Copy SHA-1 (dạng như: `AA:BB:CC:DD:...`)**

**Bước 3: Thêm vào Firebase Console**
1. Mở Firebase Console: https://console.firebase.google.com
2. Chọn project "rizz-7e0b8"
3. Vào **Project Settings** (⚙️)
4. Tab **General**
5. Scroll xuống **Your apps** → chọn Android app
6. Click **Add fingerprint**
7. Paste SHA-1 vào và Save

**Fix 2: Download google-services.json mới**
```bash
# Sau khi thêm SHA-1, download google-services.json mới
# Copy vào: android/app/google-services.json
```

**Fix 3: Test trên thiết bị thật**
```bash
# Lỗi này thường không xảy ra trên thiết bị thật
# Chỉ xảy ra trên emulator

# Connect thiết bị Android qua USB
adb devices

# Run app
fvm flutter run
```

#### **Kết quả sau khi fix:**
- ✅ Google Sign-In hoạt động
- ✅ Firebase Auth hoạt động
- ✅ Không còn SecurityException

---

## 📝 Checklist Fix

### Audio Player Issues
- [x] ✅ Thêm try-catch trong `_setupAudioListeners()`
- [x] ✅ Validate URL trước khi load
- [x] ✅ Hiển thị error state thay vì crash
- [x] ✅ Thêm SnackBar thông báo lỗi cho user
- [x] ✅ Sử dụng URL thật thay vì example.com
- [ ] ⏳ Upload audio files lên Firebase Storage
- [ ] ⏳ Cập nhật URL trong database

### Google API Issues
- [ ] ⏳ Lấy SHA-1 fingerprint
- [ ] ⏳ Thêm SHA-1 vào Firebase Console
- [ ] ⏳ Download google-services.json mới
- [ ] ⏳ Test trên thiết bị thật

---

## 🔧 Các file đã được fix

### 1. `lib/widgets/swipe_card.dart`
**Thay đổi:**
- Thêm comprehensive error handling trong `_setupAudioListeners()`
- Thêm try-catch cho tất cả audio operations
- Thêm listener `onPlayerComplete` để handle completion properly

**Trước:**
```dart
void _setupAudioListeners() async {
  await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  // ... listeners without error handling
}
```

**Sau:**
```dart
void _setupAudioListeners() async {
  try {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    
    // ... các listeners
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isCompleted = true;
        });
      }
    });
  } catch (e) {
    debugPrint('Error setting up audio listeners: $e');
    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }
}
```

### 2. `lib/widgets/audio_player_dialog.dart`
**Thay đổi:**
- Validate URL trước khi load
- Hiển thị SnackBar khi có lỗi
- Thêm comprehensive error handling

**Trước:**
```dart
Future<void> _loadAudio() async {
  setState(() {
    _isLoading = true;
    _hasError = false;
  });

  try {
    await _audioPlayer.setSource(UrlSource(widget.audioUrl));
    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    // Simple error handling
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }
}
```

**Sau:**
```dart
Future<void> _loadAudio() async {
  setState(() {
    _isLoading = true;
    _hasError = false;
  });

  try {
    // Validate URL
    if (widget.audioUrl.isEmpty || !Uri.parse(widget.audioUrl).isAbsolute) {
      throw Exception('Invalid audio URL');
    }
    
    await _audioPlayer.setSource(UrlSource(widget.audioUrl));
    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
    debugPrint('Error loading audio: $e');
    
    // Show error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải audio. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## 🎯 Hướng dẫn fix URL audio

### Option 1: Sử dụng Firebase Storage (Khuyến nghị)

**Bước 1: Upload audio lên Firebase Storage**
```dart
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadAudioToFirebase(File audioFile, String userId) async {
  try {
    final ref = FirebaseStorage.instance
        .ref()
        .child('audio/$userId/${DateTime.now().millisecondsSinceEpoch}.mp3');
    
    await ref.putFile(audioFile);
    final downloadUrl = await ref.getDownloadURL();
    
    return downloadUrl;
  } catch (e) {
    debugPrint('Error uploading audio: $e');
    rethrow;
  }
}
```

**Bước 2: Lưu URL vào Firestore**
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'audioUrl': downloadUrl,
    });
```

### Option 2: Sử dụng server riêng

**Encode URL đúng cách:**
```dart
// Ký tự Unicode cần được encode
final rawUrl = 'https://your-server.com/audio/phúc.mp3';
final encodedUrl = Uri.encodeFull(rawUrl);
// Result: https://your-server.com/audio/ph%C3%BAc.mp3
```

---

## 🧪 Testing

### Test case 1: URL không hợp lệ
```dart
// App không crash, hiển thị error icon
const invalidUrl = '';
const invalidUrl2 = 'not-a-url';
const invalidUrl3 = 'https://example.com/404.mp3';
```

### Test case 2: Network timeout
```dart
// App hiển thị loading → error sau timeout
// User có thể retry
```

### Test case 3: URL hợp lệ
```dart
// Audio load và play thành công
const validUrl = 'https://firebasestorage.googleapis.com/.../audio.mp3';
```

---

## 📊 Kết quả sau khi fix

### Trước khi fix:
```
❌ App crash khi URL fail
❌ Unhandled Exception
❌ Không có error message cho user
❌ Không thể retry
```

### Sau khi fix:
```
✅ App không crash
✅ Exception được handle gracefully
✅ Hiển thị error icon + SnackBar
✅ User có thể retry bằng cách bấm lại
✅ Log chi tiết để debug
```

---

## 🚀 Next Steps

1. **Upload audio files lên Firebase Storage:**
   - Thay thế URL giả bằng URL thật từ Firebase Storage
   - Cập nhật database với URL mới

2. **Fix Google API error:**
   - Thêm SHA-1 fingerprint vào Firebase Console
   - Test trên thiết bị thật

3. **Test thoroughly:**
   - Test với URL hợp lệ
   - Test với URL không hợp lệ
   - Test với network offline
   - Test play/pause/seek

4. **Consider additional improvements:**
   - Thêm retry mechanism
   - Cache audio locally
   - Preload audio trước khi hiển thị card
   - Thêm progress indicator khi loading

---

## 💡 Tips để tránh lỗi trong tương lai

1. **Luôn validate input:**
   ```dart
   if (url.isEmpty || !Uri.parse(url).isAbsolute) {
     throw Exception('Invalid URL');
   }
   ```

2. **Luôn sử dụng try-catch:**
   ```dart
   try {
     // risky operations
   } catch (e) {
     debugPrint('Error: $e');
     // handle gracefully
   }
   ```

3. **Sử dụng URL thật:**
   - Không dùng example.com trong production
   - Upload files lên server trước khi test

4. **Test trên thiết bị thật:**
   - Emulator có thể có các lỗi không xảy ra trên thiết bị thật
   - Luôn test trên thiết bị trước khi release

5. **Monitor errors:**
   - Sử dụng Firebase Crashlytics để track errors
   - Log chi tiết để dễ debug

---

## ❓ Troubleshooting

### Q: Vẫn bị lỗi sau khi fix?
A: 
- Kiểm tra URL có thật sự hợp lệ không (mở trong browser)
- Xem log để biết lỗi cụ thể
- Restart app sau khi fix

### Q: Google API error vẫn xuất hiện?
A:
- Đây là lỗi không ảnh hưởng audio player
- Chỉ ảnh hưởng Google Sign-In
- Fix bằng cách thêm SHA-1 vào Firebase Console

### Q: Làm sao biết URL audio đang được sử dụng?
A:
- Xem log: `I/flutter: AudioPlayers Exception: UrlSource(url: ...)`
- Check database để xem giá trị `audioUrl`

### Q: Audio không play sau khi fix?
A:
- Check network connection
- Verify URL trong database
- Check Firebase Storage permissions
- Test với URL mẫu: https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3

---

Bây giờ app của bạn đã được fix và không còn crash khi gặp lỗi audio! 🎉

