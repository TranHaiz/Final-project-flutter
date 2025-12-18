# 📘 Tài liệu: `login_screen.dart`

## 🎯 1. Tổng quan

File `login_screen.dart` triển khai giao diện đăng nhập và logic xác thực người dùng cho ứng dụng giám sát vườn thông minh. Module này đảm nhiệm: hiển thị form đăng nhập, xác thực thông tin người dùng, hiển thị thông báo lỗi khi đăng nhập sai, và điều hướng đến màn hình chính sau khi đăng nhập thành công.

## 🏗️ 2. Kiến trúc

**Cấu trúc**: Imports → Constants → UI Components (LoginScreen + Widgets)

**Dependencies**: `flutter/material.dart` (UI framework), `garden_manager.dart` (màn hình chính sau khi đăng nhập)

## 📊 3. Constants

**Thông tin xác thực cứng (hardcoded)**:
- `hardUsername = "haq"`: tên đăng nhập mặc định
- `hardPassword = "1"`: mật khẩu mặc định

> ⚠️ **Lưu ý bảo mật**: Đây là phương thức xác thực đơn giản cho mục đích demo/test. Trong production nên sử dụng API backend và mã hóa.

## 🖥️ 4. LoginScreen (StatefulWidget)

**Biến nội bộ**:
- `_usernameController`: TextEditingController - quản lý input username
- `_passwordController`: TextEditingController - quản lý input password
- `_errorMessage`: String? - thông báo lỗi (null nếu không có lỗi)

**Hàm xác thực**:

`_login()`: Xử lý logic đăng nhập
- So sánh username và password với `hardUsername` và `hardPassword`
- Nếu đúng: điều hướng đến `GardenScreen` bằng `Navigator.pushReplacement()` (không thể quay lại màn hình login)
- Nếu sai: cập nhật `_errorMessage` và hiển thị thông báo lỗi màu đỏ

**UI Components**:

- `title`: Text "Đăng nhập" với font size 26, bold
- `usernameField`: TextField với label "Username"
- `passwordField`: TextField với label "Password", `obscureText: true` để ẩn mật khẩu
- `errorText`: Hiển thị thông báo lỗi màu đỏ nếu có, hoặc `SizedBox.shrink()` nếu không có lỗi
- `loginButton`: ElevatedButton "Login" gọi hàm `_login()` khi nhấn

**Hàm build()**: 
- Render Scaffold với body chứa Column căn giữa
- Padding 24px xung quanh
- Sắp xếp các components theo thứ tự: title → username field → password field → error message → login button
- Sử dụng SizedBox để tạo khoảng cách giữa các elements

## ⚙️ 5. Cơ chế hoạt động

1. Người dùng mở ứng dụng → hiển thị LoginScreen
2. Nhập username và password vào các TextField
3. Nhấn nút "Login" → gọi `_login()`
4. Kiểm tra thông tin:
   - ✅ Đúng → chuyển đến GardenScreen (không thể back)
   - ❌ Sai → hiển thị "Sai username hoặc password!" màu đỏ
5. Người dùng có thể thử lại với thông tin khác

## 🔐 6. Luồng xác thực
```
Nhập thông tin → Nhấn Login
    ↓
So sánh với hardcoded credentials
    ↓
    ├─ Match → Navigator.pushReplacement → GardenScreen
    └─ No match → setState(_errorMessage) → Hiển thị lỗi
```

## 🧠 7. Tóm tắt chức năng

| Chức năng | Mô tả |
|-----------|-------|
| Form đăng nhập | Username và password fields |
| Xác thực cứng | So sánh với hardcoded credentials |
| Hiển thị lỗi | Thông báo màu đỏ khi sai thông tin |
| Điều hướng | Chuyển đến GardenScreen sau khi đăng nhập thành công |
| Ẩn mật khẩu | obscureText cho password field |
| UI đơn giản | Giao diện sạch sẽ, dễ sử dụng |

## 🔧 8. Cải tiến đề xuất

- Thay thế hardcoded credentials bằng API authentication
- Thêm "Remember me" checkbox
- Thêm "Forgot password" functionality
- Validate input trước khi submit
- Thêm loading indicator khi đang xác thực
- Lưu session token bằng SharedPreferences/SecureStorage