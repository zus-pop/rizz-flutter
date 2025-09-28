# Demo Features - Onboarding & Authentication

## 🎯 Tính năng đã thêm vào Settings

### 1. **Sign Out** (Đăng xuất hoàn toàn)
- Xóa toàn bộ dữ liệu authentication từ SharedPreferences
- Reset onboarding state
- Chuyển về Splash Screen
- User sẽ phải xem lại onboarding và login lại

### 2. **Reset Demo** (Reset chỉ onboarding)
- Chỉ reset onboarding state
- Giữ nguyên trạng thái đăng nhập
- Chuyển về Splash Screen
- User sẽ xem lại onboarding nhưng sau đó vào thẳng home (vì vẫn đã login)

## 🔄 Demo Flow

### Flow hoàn chỉnh (sau khi Sign Out):
1. **Splash Screen** (2s)
2. **Onboarding Screen** (3 màn hình)
3. **Login Page** (Phone/Google)
4. **OTP Verification** (nếu chọn phone)
5. **Home Screen**

### Flow sau Reset Demo:
1. **Splash Screen** (2s) 
2. **Onboarding Screen** (3 màn hình)
3. **Home Screen** (vì vẫn đã login)

## 🎮 Cách test

### Test luồng hoàn chỉnh:
1. Vào **Settings** → **App** tab
2. Tap **"Sign Out"**
3. Confirm → Sẽ thấy onboarding → login → home

### Test chỉ onboarding:
1. Vào **Settings** → **App** tab  
2. Tap **"Reset Demo"**
3. Confirm → Sẽ thấy onboarding → home (skip login vì vẫn đã login)

## ⚙️ Technical Details

### Sign Out thực hiện:
```dart
// Clear auth data
await authProvider.logout();

// Reset onboarding
await OnboardingService.resetOnboarding();

// Navigate to splash
Navigator.pushAndRemoveUntil(SplashScreen(), (route) => false);
```

### Reset Demo thực hiện:
```dart
// Chỉ reset onboarding (không logout)
await OnboardingService.resetOnboarding();

// Navigate to splash
Navigator.pushAndRemoveUntil(SplashScreen(), (route) => false);
```

## 📱 UI Indicators

- **Sign Out**: Red icon (logout) - "Sign out of your account"
- **Reset Demo**: Orange icon (refresh) - "Reset onboarding for demo purposes"

## 🚀 Production Notes

Trong production:
- Xóa nút "Reset Demo" 
- Chỉ giữ "Sign Out"
- Sign Out chỉ clear auth data, không reset onboarding
- Onboarding chỉ hiện cho user mới lần đầu