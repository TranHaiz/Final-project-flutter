// @file       bluetooth.dart
// @copyright  Copyright (C) 2025 Your_Organization. All rights reserved.
// @license    MIT License
// @version    1.0.0
// @date       2025-10-12
// @author     Tran Hai
// @brief      Handles Bluetooth scanning, connection, and data communication for the Garden Smart Home app.
// @note       Uses Flutter Bluetooth Serial and Permission Handler to discover devices, manage connections, and receive data.

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'garden_manager.dart';

List<double> latestValues = [0]; // lưu dữ liệu MCU gửi lên

// ========================== Bluetooth Service ==========================
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

  // Listener dữ liệu MCU
  void startListening(void Function(List<double>) onData) {
    if (_connection == null) return;

    _connection!.input?.listen((data) {
      final msg = String.fromCharCodes(data);
      final lines = msg.split('\n');
      for (var line in lines) {
        if (line.isNotEmpty) {
          final numbers = line
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) => double.tryParse(e))
              .where((e) => e != null)
              .map((e) => e!)
              .toList();
          if (numbers.isNotEmpty) {
            onData(numbers);
          }
        }
      }
    });
  }
}

// ========================== Permission Helper ==========================
Future<void> _checkPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.location,
  ].request();
}

// ========================== Bluetooth Page ==========================
class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  BluetoothState _state = BluetoothState.UNKNOWN;
  List<BluetoothDiscoveryResult> _devices = [];
  bool _discovering = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    final s = await FlutterBluetoothSerial.instance.state;
    setState(() => _state = s);

    FlutterBluetoothSerial.instance.onStateChanged().listen((v) {
      if (mounted) setState(() => _state = v);
    });
  }

  Future<void> _toggle(bool on) async => on
      ? await FlutterBluetoothSerial.instance.requestEnable()
      : await FlutterBluetoothSerial.instance.requestDisable();

  Future<void> _startDiscovery() async {
    await _checkPermissions();
    setState(() {
      _devices.clear();
      _discovering = true;
    });

    FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((r) {
          setState(() {
            final i = _devices.indexWhere(
              (e) => e.device.address == r.device.address,
            );
            if (i >= 0) {
              _devices[i] = r;
            } else {
              _devices.add(r);
            }
          });
        })
        .onDone(() => setState(() => _discovering = false));
  }

  Future<void> _getBonded() async {
    final list = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(
      () => _devices = list
          .map((d) => BluetoothDiscoveryResult(device: d, rssi: 0))
          .toList(),
    );
  }

  Future<void> _connect(BluetoothDevice d) async {
    try {
      final c = await BluetoothConnection.toAddress(d.address);
      BluetoothService.instance.setConnection(c, d);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã kết nối ${d.name ?? d.address}')),
      );

      // Bật listener tự động cập nhật latestValues
      BluetoothService.instance.startListening((numbers) {
        setState(() {
          latestValues = numbers;
        });
      });

      setState(() {}); // cập nhật UI
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kết nối thất bại')));
    }
  }

  Future<void> _disconnect() async {
    await BluetoothService.instance.disconnect();
    setState(() {});
  }

  Widget _buildDeviceTile(BluetoothDiscoveryResult r) {
    final d = r.device;
    final connected =
        BluetoothService.instance.currentDevice?.address == d.address;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: Colors.blue),
        title: Text(d.name ?? 'Không tên'),
        subtitle: Text(d.address),
        trailing: connected
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _disconnect,
              )
            : ElevatedButton(
                onPressed: BluetoothService.instance.currentDevice == null
                    ? () => _connect(d)
                    : null,
                child: const Text('Kết nối'),
              ),
      ),
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      title: const Text('Bluetooth'),
      actions: [
        IconButton(
          icon: Icon(
            _state.isEnabled
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
          ),
          onPressed: () => _toggle(!_state.isEnabled),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: Colors.red),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GardenScreen()),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        children: [
          if (BluetoothService.instance.currentDevice != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade100,
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_connected, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      BluetoothService.instance.currentDevice!.name ??
                          BluetoothService.instance.currentDevice!.address,
                    ),
                  ),
                  TextButton(onPressed: _disconnect, child: const Text('Ngắt')),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _discovering ? null : _startDiscovery,
                    icon: const Icon(Icons.search),
                    label: Text(_discovering ? 'Đang quét...' : 'Quét mới'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getBonded,
                    icon: const Icon(Icons.devices),
                    label: const Text('Đã ghép nối'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(child: Text('Không có thiết bị'))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (_, i) => _buildDeviceTile(_devices[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
