import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

Future<void> _checkBluetoothPermissions() async {
  if (await Permission.bluetoothScan.isDenied) {
    await Permission.bluetoothScan.request();
  }
  if (await Permission.bluetoothConnect.isDenied) {
    await Permission.bluetoothConnect.request();
  }
  if (await Permission.bluetoothAdvertise.isDenied) {
    await Permission.bluetoothAdvertise.request();
  }
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
}

class BluetoothScanPage extends StatefulWidget {
  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDiscoveryResult> _devices = [];
  bool _isDiscovering = false;
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _checkBluetoothPermissions(); // 🔹 Quan trọng: xin quyền ngay khi vào app
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      BluetoothState state = await FlutterBluetoothSerial.instance.state;
      setState(() => _bluetoothState = state);

      FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
        if (mounted) setState(() => _bluetoothState = state);
      });
    } catch (e) {
      print("Lỗi khởi tạo Bluetooth: $e");
    }
  }

  Future<void> _toggleBluetooth(bool enable) async {
    if (enable) {
      await FlutterBluetoothSerial.instance.requestEnable();
    } else {
      await FlutterBluetoothSerial.instance.requestDisable();
    }
  }

  Future<void> startDiscovery() async {
    await _checkBluetoothPermissions(); // 🔹 Đảm bảo xin quyền trước khi quét
    setState(() {
      _devices.clear();
      _isDiscovering = true;
    });

    FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((result) {
          setState(() {
            final existingIndex = _devices.indexWhere(
              (element) => element.device.address == result.device.address,
            );

            if (existingIndex >= 0) {
              _devices[existingIndex] = result;
            } else {
              _devices.add(result);
            }
          });
        })
        .onDone(() {
          setState(() => _isDiscovering = false);
        });
  }

  Future<void> getBondedDevices() async {
    try {
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial
          .instance
          .getBondedDevices();

      setState(() {
        _devices = bondedDevices
            .map((device) => BluetoothDiscoveryResult(device: device, rssi: 0))
            .toList();
      });
    } catch (e) {
      print("Lỗi lấy danh sách đã ghép nối: $e");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(
        device.address,
      );

      if (!mounted) return;

      setState(() {
        _connection = connection;
        _connectedDevice = device;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã kết nối với ${device.name ?? device.address}'),
        ),
      );

      connection.input
          ?.listen((Uint8List data) {
            String received = String.fromCharCodes(data);
            print('Nhận: $received');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nhận: $received'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          })
          .onDone(() {
            if (mounted) {
              setState(() {
                _connection = null;
                _connectedDevice = null;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Đã ngắt kết nối')));
            }
          });
    } catch (e) {
      print("Lỗi kết nối: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể kết nối: $e')));
    }
  }

  void sendData(String text) {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(Uint8List.fromList(text.codeUnits));
      _connection!.output.allSent.then((_) => print('Đã gửi: $text'));
    }
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.finish();
      setState(() {
        _connection = null;
        _connectedDevice = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã ngắt kết nối')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Classic (HC-05)'),
        actions: [
          IconButton(
            icon: Icon(
              _bluetoothState.isEnabled
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
            ),
            onPressed: () => _toggleBluetooth(!_bluetoothState.isEnabled),
            tooltip: _bluetoothState.isEnabled
                ? 'Tắt Bluetooth'
                : 'Bật Bluetooth',
          ),
          if (_connectedDevice != null)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: disconnect,
              tooltip: 'Ngắt kết nối',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_connectedDevice != null)
            Container(
              color: Colors.green.shade100,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.bluetooth_connected, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đã kết nối: ${_connectedDevice!.name ?? _connectedDevice!.address}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(onPressed: disconnect, child: Text('Ngắt')),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => sendData('1'),
                          child: Text('Gửi: 1'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => sendData('0'),
                          child: Text('Gửi: 0'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDiscovering ? null : startDiscovery,
                    icon: Icon(
                      _isDiscovering ? Icons.hourglass_empty : Icons.search,
                    ),
                    label: Text(
                      _isDiscovering ? 'Đang quét...' : 'Quét thiết bị mới',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: getBondedDevices,
                    icon: Icon(Icons.devices),
                    label: Text('Đã ghép nối'),
                  ),
                ),
              ],
            ),
          ),
          if (!_bluetoothState.isEnabled)
            Container(
              color: Colors.orange.shade100,
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Bluetooth đang tắt. Nhấn icon trên để bật.'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _isDiscovering
                          ? 'Đang tìm kiếm thiết bị...'
                          : 'Nhấn "Quét thiết bị mới" hoặc "Đã ghép nối"',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final result = _devices[index];
                      final device = result.device;

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: Colors.blue,
                            size: 36,
                          ),
                          title: Text(
                            device.name ?? 'Thiết bị không tên',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Địa chỉ: ${device.address}'),
                              if (result.rssi != 0)
                                Text('RSSI: ${result.rssi} dBm'),
                              if (device.isBonded)
                                Text(
                                  '✓ Đã ghép nối',
                                  style: TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: _connection != null
                                ? null
                                : () => connectToDevice(device),
                            child: Text('Kết nối'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
