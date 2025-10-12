import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  BluetoothConnection? _connection;
  BluetoothDevice? _currentDevice;

  static final BluetoothService instance = BluetoothService._internal();
  BluetoothService._internal();

  BluetoothDevice? get currentDevice => _currentDevice;
  bool get hasConnection => _connection != null && _connection!.isConnected;

  void setConnection(BluetoothConnection c, [BluetoothDevice? device]) {
    _connection = c;
    if (device != null) _currentDevice = device;
  }

  bool isConnected(BluetoothDevice d) {
    return _currentDevice?.address == d.address && hasConnection;
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _currentDevice = null;
  }

  void onReceive(String data) {
    // Xử lý dữ liệu MCU gửi lên
    print('Received: $data');
  }
}
