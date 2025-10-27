# 📘 Tài liệu: `main.dart`

## 🎯 1. Tổng quan
File `main.dart` là điểm khởi đầu của ứng dụng Smart Garden, đảm nhiệm: khởi tạo ứng dụng Flutter, cấu hình theme và thiết lập, điều hướng đến màn hình đăng nhập ban đầu.

## 🏗️ 2. Kiến trúc
**Cấu trúc**: Imports → Main Function → MyApp (Root Widget). **Dependencies**: `flutter/material.dart` (Flutter framework), `login_screen.dart` (màn hình đăng nhập).

## 🚀 3. Entry Point
**Function `main()`**: Hàm khởi động ứng dụng, gọi `runApp(const MyApp())` để chạy widget gốc. Đây là điểm bắt đầu thực thi của toàn bộ ứng dụng.

## 🎨 4. MyApp (StatelessWidget)
**Mô tả**: Widget gốc của ứng dụng, không có state thay đổi. **Hàm build()**: Trả về MaterialApp với cấu hình `title: 'Smart Garden'` (tiêu đề ứng dụng), `theme: ThemeData(primarySwatch: Colors.green)` (theme màu xanh lá), `home: const LoginScreen()` (màn hình mặc định), `debugShowCheckedModeBanner: false` (ẩn banner DEBUG).

## ⚙️ 5. Cơ chế hoạt động
Khởi động app → main() → runApp(MyApp()) → MaterialApp được khởi tạo → Áp dụng theme (Colors.green) → Hiển thị LoginScreen (màn hình đầu tiên).

## 🎨 6. Theme Configuration
**Primary Color**: `Colors.green` - phù hợp với theme "Smart Garden". **Áp dụng cho**: AppBar background, FloatingActionButton, Accent colors, Switch/Checkbox/Radio buttons trong toàn bộ ứng dụng.

## 🧠 7. Tóm tắt chức năng
| Chức năng | Mô tả |
|-----------|-------|
| Entry point | Khởi động ứng dụng Flutter |
| Theme setup | Cấu hình màu sắc và giao diện chung |
| Initial route | Điều hướng đến LoginScreen |
| App configuration | Cấu hình title và debug settings |
| Root widget | Cung cấp MaterialApp cho toàn bộ ứng dụng |

## 🔧 8. Đặc điểm kỹ thuật
**Widget type**: StatelessWidget (không cần quản lý state). **Design pattern**: Single root widget pattern. **Navigation**: Sử dụng `home` property thay vì `initialRoute`. **Performance**: Sử dụng `const` constructor để optimize.

## 💡 9. Lưu ý
File này rất đơn giản và ít khi cần thay đổi. Để thêm routes phức tạp có thể sử dụng `routes` hoặc `onGenerateRoute`. Theme có thể mở rộng với `darkTheme` cho dark mode. Có thể thêm `localizationsDelegates` cho đa ngôn ngữ.