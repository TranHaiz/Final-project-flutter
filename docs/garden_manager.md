# 📘 Tài liệu: `garden_manager.dart`

## 🎯 1. Tổng quan

File `garden_manager.dart` là module quản lý trung tâm của ứng dụng giám sát vườn thông minh, đảm nhiệm: quản lý dữ liệu vườn trồng, theo dõi môi trường (nhiệt độ, độ ẩm, ánh sáng) theo thời gian thực, xử lý tương tác người dùng, và đồng bộ dữ liệu qua Bluetooth với lưu trữ cục bộ.

## 🏗️ 2. Kiến trúc

**Cấu trúc**: Imports & Dependencies → Constants & Global Variables → Data Models (Plant, Garden) → UI Components (GardenScreen + Widgets)

**Dependencies**: `dart:convert`, `dart:io`, `dart:async` (xử lý JSON, file, async), `flutter/material.dart` (UI), `path_provider` (đường dẫn ứng dụng), `login_screen.dart`, `bluetooth.dart`, `control_screen.dart` (màn hình và services).

## 📊 3. Constants & Variables

- `maxGardens = 4`: số vườn tối đa
- `plantTypes`: danh sách loại cây
- `plantIcons`, `plantColors`: icon và màu cho từng loại cây
- `temperature`, `humidity`, `lux`: dữ liệu môi trường cho 4 vườn

## 🗃️ 4. Data Models

**Class Plant**: thuộc tính `name`, methods `toJson()` và `fromJson()` để chuyển đổi object ↔ JSON.

**Class Garden**: thuộc tính `name` và `plants` (List<Plant>), methods `toJson()` và `fromJson()` để serialize/deserialize. Cấu trúc JSON: `{"name": "Vườn 1", "plants": [{"name": "Xoài"}]}`.

## 🖥️ 5. GardenScreen (StatefulWidget)

**Biến nội bộ**:
- `gardens`: List<Garden> - danh sách vườn
- `selectedGarden`: int - vườn đang chọn
- `_btStreamSub`: StreamSubscription - nhận dữ liệu Bluetooth

**Hàm xử lý dữ liệu**:
- `localFile()`: xác định vị trí file `gardens.json`
- `saveGardens()`: lưu dữ liệu vườn xuống file
- `loadGardens()`: đọc dữ liệu từ file (hoặc tạo "Vườn 1" mặc định)

**Bluetooth Stream**: Nhận dữ liệu từ `BluetoothService.instance.dataStream`, cập nhật liên tục `temperature`, `humidity`, `lux` cho từng vườn.

**Hàm thao tác**:
- `addGarden()`: thêm vườn mới (nếu < maxGardens)
- `deleteGarden(index)`: xóa vườn theo chỉ số
- `addPlant()`: hiển thị dialog chọn loại cây để thêm
- `deletePlant(index)`: xóa cây trong vườn hiện tại

**Widgets phụ**:
- `buildEnvInfoCard()`: hiển thị nhiệt độ, độ ẩm, ánh sáng
- `buildPlantList()`: danh sách cây + nút "Thêm cây"
- `buildAppBar()`: thanh công cụ (Bluetooth 🔵, Điều khiển ⚙️, Xóa vườn ❌, Đăng xuất 🔒)
- `buildBottomNav()`: thanh điều hướng giữa các vườn hoặc thêm vườn mới

**Hàm build()**: Hiển thị CircularProgressIndicator khi chưa có dữ liệu, sau đó render giao diện với AppBar, Card, ListView, BottomNavigationBar. Cập nhật dữ liệu theo thời gian thực.

## ⚙️ 6. Cơ chế hoạt động

1. Mở ứng dụng → `loadGardens()` đọc JSON từ bộ nhớ
2. Nhận dữ liệu từ MCU qua Bluetooth → cập nhật thông số môi trường
3. Người dùng thêm/xóa vườn hoặc cây, điều hướng giữa các vườn
4. Lưu dữ liệu tự động mỗi khi thay đổi
5. Đóng ứng dụng → dữ liệu được lưu lại

## 🧠 7. Tóm tắt chức năng

| Chức năng | Mô tả |
|-----------|-------|
| Quản lý nhiều vườn | Giới hạn tối đa 4 vườn |
| Theo dõi môi trường | Nhiệt độ, độ ẩm, ánh sáng real-time |
| Lưu trữ cục bộ | Tự động ghi/đọc `gardens.json` |
| Bluetooth | Nhận dữ liệu cảm biến từ MCU |
| Giao diện động | Dễ mở rộng, trực quan, thân thiện |