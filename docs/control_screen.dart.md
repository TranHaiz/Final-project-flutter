# 📘 Tài liệu: `control_screen.dart`

## 🎯 1. Tổng quan

File `control_screen.dart` cung cấp giao diện điều khiển các thiết bị chấp hành (actuators) như đèn LED thông qua công tắc (switches). Module này đảm nhiệm: quản lý trạng thái bật/tắt của các thiết bị, lưu trữ trạng thái cục bộ, đồng bộ hóa với thiết bị phần cứng qua Bluetooth, và duy trì trạng thái khi ứng dụng đóng/mở lại.

## 🏗️ 2. Kiến trúc

**Cấu trúc**: Imports → Constants → Data Models (Actuator) → UI Components (ControlScreen + Widgets)

**Dependencies**: `flutter/material.dart` (UI framework), `shared_preferences` (lưu trữ cục bộ), `garden_manager.dart` (màn hình vườn), `bluetooth.dart` (service kết nối Bluetooth)

## 📊 3. Constants

- `numbersActuator = 4`: số lượng thiết bị chấp hành (LED) cố định

## 🗃️ 4. Data Models

**Class Actuator**: Đại diện cho một thiết bị chấp hành.

**Thuộc tính**:
- `state` (bool): trạng thái bật/tắt của thiết bị
- `name` (String): tên hiển thị của thiết bị

**Constructor**: `Actuator({required name, state = false})` - khởi tạo với tên bắt buộc, trạng thái mặc định là tắt.

## 🖥️ 5. ControlScreen (StatefulWidget)

**Biến nội bộ**:
- `actuators`: List<Actuator> - danh sách 4 LED (Led 1, Led 2, Led 3, Led 4)
- `_isLoading`: bool - trạng thái đang tải dữ liệu

**Lifecycle Management**: Implement `WidgetsBindingObserver` để theo dõi lifecycle của app và lưu trạng thái khi app chuyển sang background hoặc bị đóng.

**Hàm xử lý dữ liệu**:

- `initState()`: Đăng ký observer và gọi `_loadActuatorStates()`
- `dispose()`: Hủy observer và lưu trạng thái trước khi thoát
- `didChangeAppLifecycleState()`: Lưu trạng thái khi app chuyển sang paused/inactive/detached

**Hàm lưu trữ**:

- `_loadActuatorStates()`: Đọc trạng thái đã lưu từ SharedPreferences, sau đó đồng bộ với thiết bị
- `_saveActuatorState(index, value)`: Lưu trạng thái của một LED cụ thể
- `_saveAllActuatorStates()`: Lưu trạng thái của tất cả LED
- `_clearAllStates()`: Xóa tất cả trạng thái đã lưu và reset về false

**Hàm đồng bộ Bluetooth**:

- `_syncStatesWithDevice()`: Gửi lệnh đồng bộ trạng thái tất cả LED đến thiết bị qua Bluetooth. Format: `"state0,state1,state2,state3\n"`

**Widgets phụ**:

- `buildActuatorList()`: Hiển thị danh sách LED với Card/ListTile. Mỗi LED có:
  - Icon lightbulb (màu vàng khi bật, xám khi tắt)
  - Tên LED và trạng thái ("Đang bật"/"Đang tắt")
  - Switch để bật/tắt, khi thay đổi sẽ:
    1. Cập nhật state
    2. Gửi lệnh đến thiết bị: `"index+state"`
    3. Lưu trạng thái vào SharedPreferences

- `buildAppBar()`: Thanh công cụ với 3 nút:
  - Sync 🔄: đồng bộ trạng thái với thiết bị
  - Reset 🔃: reset tất cả LED về trạng thái tắt
  - Logout 🔒: lưu trạng thái và quay về GardenScreen

**Hàm build()**: Render Scaffold với AppBar và body chứa danh sách LED. Hiển thị CircularProgressIndicator khi đang tải.

## ⚙️ 6. Cơ chế hoạt động

1. Mở màn hình → `_loadActuatorStates()` đọc trạng thái từ SharedPreferences
2. Tự động đồng bộ trạng thái với thiết bị qua Bluetooth
3. Người dùng bật/tắt LED → gửi lệnh qua Bluetooth và lưu vào SharedPreferences
4. Khi app chuyển sang background/bị đóng → tự động lưu trạng thái
5. Khi quay lại → trạng thái được phục hồi từ SharedPreferences

## 🔄 7. Giao thức Bluetooth

**Lệnh điều khiển đơn lẻ**: `"index+state"` (ví dụ: `"0+true"`, `"2+false"`)

**Lệnh đồng bộ toàn bộ**: `"state0,state1,state2,state3\n"` (ví dụ: `"true,false,true,false\n"`)

## 🧠 8. Tóm tắt chức năng

| Chức năng | Mô tả |
|-----------|-------|
| Điều khiển LED | Bật/tắt 4 LED độc lập qua switches |
| Lưu trữ trạng thái | Tự động lưu vào SharedPreferences |
| Đồng bộ Bluetooth | Gửi lệnh real-time đến MCU |
| Khôi phục trạng thái | Tự động load trạng thái khi mở lại |
| Lifecycle-aware | Lưu trạng thái khi app background/đóng |
| Reset | Tắt tất cả LED và xóa dữ liệu đã lưu |