# Phân tích mã nguồn Flutter – Giao tiếp Bluetooth
## I. Tóm tắt chương trình
Ứng dụng được phát triển bằng **Flutter** nhằm giao tiếp với vi điều khiẻn thông qua **Bluetooth Classic (Serial Port Profile)**. Mục tiêu chính của chương trình là:
- Cho phép người dùng **quét, xem danh sách thiết bị Bluetooth**, và **kết nối** với một thiết bị cụ thể.  
- Khi kết nối thành công, chương trình **trao đổi dữ liệu hai chiều** với thiết bị (gửi lệnh – nhận dữ liệu phản hồi).  
- **Dữ liệu phản hồi** được đọc từ cổng Bluetooth, xử lý, chuyển đổi thành định dạng số, rồi truyền đến **Stream** để các phần khác của ứng dụng (ví dụ như giao diện hiển thị giá trị cảm biến) có thể sử dụng.  
- Giao diện người dùng cho phép người dùng **bật/tắt kết nối**, **gửi lệnh điều khiển**, và **xem dữ liệu nhận được theo thời gian thực**.

Ứng dụng gồm hai phần chính:
1. **Lớp dịch vụ Bluetooth (`BluetoothService`)**: quản lý việc kết nối, ngắt kết nối, gửi và nhận dữ liệu.  
2. **Giao diện quét và điều khiển (`BluetoothScanPage`)**: cung cấp thao tác người dùng như quét, chọn, kết nối, và hiển thị trạng thái.

---

## II. Phân bổ code

### 1. Thư viện sử dụng
- `flutter_bluetooth_serial`: cung cấp API Bluetooth cho Flutter (quét, kết nối, truyền dữ liệu).
- `permission_handler`: xin quyền Bluetooth và vị trí (cần thiết khi quét thiết bị).
- `async`: hỗ trợ xử lý luồng bất đồng bộ.
- `convert`: hỗ trợ mã hóa và giải mã dữ liệu (UTF-8).
- `typed_data`: hỗ trợ làm việc với byte và buffer dữ liệu.

---

### 2. Biến và cấu trúc dữ liệu chính
- `latestValues`: danh sách chứa dữ liệu mới nhất đọc được từ thiết bị (dạng `List<double>`).  
- `BluetoothService`: lớp singleton – chỉ tạo một thể hiện duy nhất trong toàn bộ ứng dụng để tránh trùng kết nối.  
- `StreamController<List<double>>`: đối tượng quản lý dòng dữ liệu bất đồng bộ, giúp truyền dữ liệu mới từ thiết bị đến các widget hiển thị theo thời gian thực.  

---

### 3. Lớp `BluetoothService`
Đây là phần lõi điều khiển Bluetooth.

**Các thuộc tính:**
- `connection`: đối tượng `BluetoothConnection` quản lý kênh truyền dữ liệu.  
- `isConnected`: trạng thái hiện tại của kết nối (true/false).  
- `dataStreamController`: bộ phát dữ liệu đến các widget.  

**Các phương thức chính:**
- `connect(String address)`:  
  - Tạo kết nối Bluetooth đến địa chỉ MAC được chọn.  
  - Khi kết nối thành công, bắt đầu **lắng nghe dữ liệu đầu vào (input stream)** từ thiết bị.  
  - Mỗi khi có dữ liệu, chương trình đọc chuỗi, tách thành các giá trị riêng biệt (thường theo dấu phẩy hoặc ký tự xuống dòng), chuyển chúng sang dạng số (`double`), rồi phát ra qua `dataStreamController`.  

- `disconnect()`:  
  - Đóng kết nối Bluetooth.  
  - Giải phóng tài nguyên và ngắt stream.  

- `sendData(String message)`:  
  - Gửi chuỗi dữ liệu UTF-8 sang thiết bị qua cổng Bluetooth.  
  - Dùng trong các trường hợp gửi lệnh điều khiển, yêu cầu dữ liệu, hoặc kích hoạt thiết bị.  

- `dataStream`:  
  - Trả về `Stream<List<double>>` giúp các widget có thể lắng nghe dữ liệu cập nhật liên tục.  

---

### 4. Hàm `_checkPermissions()`
Hàm này được gọi khi ứng dụng khởi động.  
Nhiệm vụ của nó là đảm bảo ứng dụng có đủ quyền truy cập Bluetooth:
- **Bluetooth scan**: cần cho việc tìm thiết bị mới.  
- **Bluetooth connect**: cần để kết nối thiết bị.  
- **Vị trí (location)**: Android yêu cầu quyền này khi quét Bluetooth.  

Nếu quyền bị từ chối, chương trình sẽ liên tục yêu cầu cho đến khi được cấp phép, đảm bảo ứng dụng hoạt động trơn tru.

---

### 5. Widget `BluetoothScanPage`
Đây là **giao diện chính** của người dùng.  
Nó bao gồm danh sách các thiết bị Bluetooth, nút bấm quét (Scan), xem danh sách đã ghép đôi (Paired), và điều khiển kết nối (Connect/Disconnect).

**Các thành phần chính:**
- **Biến cục bộ:**
  - `_devices`: danh sách thiết bị Bluetooth (kết quả quét hoặc đã paired).
  - `_connectedDevice`: thiết bị hiện đang kết nối.
  - `_isDiscovering`: trạng thái đang quét thiết bị.
  - `_isConnected`: trạng thái đã kết nối hay chưa.

**Các hàm trong widget:**
- `_initBluetooth()`:  
  Kiểm tra trạng thái Bluetooth adapter, khởi động nếu cần.  
- `_startDiscovery()`:  
  Thực hiện quét thiết bị mới, cập nhật danh sách `_devices`.  
- `_getBonded()`:  
  Lấy danh sách các thiết bị đã ghép đôi sẵn.  
- `_connect(BluetoothDevice device)`:  
  Gọi `BluetoothService.connect()` để kết nối đến thiết bị được chọn.  
- `_disconnect()`:  
  Gọi `BluetoothService.disconnect()` để ngắt kết nối hiện tại.  
- `build(BuildContext context)`:  
  Dựng giao diện với các phần:  
  - Danh sách thiết bị (ListView).  
  - Các nút chức năng (Scan, Paired, Connect, Disconnect).  
  - Hiển thị thông tin thiết bị đang kết nối và trạng thái kết nối.

---

## III. Luồng chạy chương trình

1. **Khởi động ứng dụng**
   - `BluetoothScanPage` được khởi tạo.  
   - Hàm `_checkPermissions()` chạy đầu tiên để đảm bảo quyền Bluetooth.  
   - Sau khi được cấp quyền, `_initBluetooth()` kiểm tra và kích hoạt Bluetooth adapter nếu cần.

2. **Quét thiết bị**
   - Người dùng nhấn nút “Scan”.  
   - `_startDiscovery()` được gọi, tìm kiếm thiết bị Bluetooth trong phạm vi gần.  
   - Các thiết bị tìm thấy được thêm vào danh sách `_devices` và hiển thị trên giao diện.

3. **Kết nối thiết bị**
   - Khi người dùng chọn một thiết bị → gọi `_connect(device)`.  
   - `BluetoothService.connect()` được kích hoạt, tạo kết nối thông qua `BluetoothConnection`.  
   - Sau khi kết nối thành công, `isConnected` đặt thành `true`.

4. **Trao đổi dữ liệu**
   - Dữ liệu gửi từ ESP32 đến điện thoại được nhận qua `connection.input`.  
   - Chương trình đọc chuỗi, tách giá trị theo ký tự phân cách, chuyển sang kiểu `double`.  
   - Dữ liệu được đưa vào `dataStream`, phát ra để widget khác hiển thị.  
   - Nếu người dùng muốn gửi dữ liệu điều khiển, gọi `BluetoothService.sendData(message)`.

5. **Cập nhật giao diện**
   - Widget lắng nghe `dataStream` thông qua `StreamBuilder` hoặc `StreamSubscription`.  
   - Mỗi khi có dữ liệu mới, danh sách `latestValues` được cập nhật, đồng thời các widget hiển thị (ví dụ biểu đồ, số đo, trạng thái) được làm mới tự động.

6. **Ngắt kết nối**
   - Khi người dùng nhấn “Disconnect”, hàm `_disconnect()` được gọi.  
   - `BluetoothService.disconnect()` đóng kết nối, ngắt stream, cập nhật `isConnected = false`.  
   - Giao diện hiển thị lại trạng thái ngắt kết nối.

---

## IV. Tổng kết
Chương trình thể hiện cấu trúc **chia tách rõ ràng giữa xử lý logic Bluetooth và giao diện hiển thị**:
- Lớp `BluetoothService` đóng vai trò **Model/Controller**, chịu trách nhiệm điều khiển kết nối và luồng dữ liệu.  
- `BluetoothScanPage` đóng vai trò **View**, hiển thị danh sách thiết bị và phản hồi dữ liệu theo thời gian thực.  

Kiến trúc này giúp dễ dàng mở rộng chương trình, ví dụ:
- Thêm chức năng lưu dữ liệu nhận được.
- Hiển thị biểu đồ cảm biến theo thời gian.
- Gửi lệnh điều khiển thiết bị IoT trực tiếp từ ứng dụng.
