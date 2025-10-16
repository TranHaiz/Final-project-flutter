// @file       bluetooth.dart
// @copyright  Copyright (C) 2025 HAQ. All rights reserved.
// @license    This project is released under the <Your_License> License.
// @version    major.minor.patch
// @date       2025-10-12
// @author     Hai Tran
// @brief      Manages Bluetooth communication and device control.
// ============================== Imports ==============================
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'garden_manager.dart';

// =========================== Private Variables =======================
List<double> latestValues = [0];

// ============================== Classes ==============================
class BluetoothService {
  BluetoothConnection? _connection;
  BluetoothDevice? _currentDevice;
  StreamSubscription<Uint8List>? _subscription;
  final StreamController<List<double>> _dataController =
      StreamController<List<double>>.broadcast();

  static final BluetoothService instance = BluetoothService._internal();
  BluetoothService._internal();

  Stream<List<double>> get dataStream => _dataController.stream;
  BluetoothDevice? get currentDevice => _currentDevice;
  bool get hasConnection => _connection != null && _connection!.isConnected;

  Future<void> connect(BluetoothDevice device) async {
    if (hasConnection) await disconnect();

    final c = await BluetoothConnection.toAddress(device.address);
    _connection = c;
    _currentDevice = device;

    _subscription = _connection!.input!.asBroadcastStream().listen((data) {
      final msg = String.fromCharCodes(data);
      final lines = msg.split('\n');
      for (var line in lines) {
        if (line.isNotEmpty) {
          final numbers = line
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) => double.tryParse(e))
              .whereType<double>()
              .toList();
          if (numbers.isNotEmpty) _dataController.add(numbers);
        }
      }
    });
  }

  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
    } catch (_) {}
    try {
      await _connection?.finish();
    } catch (_) {}
    _subscription = null;
    _connection = null;
    _currentDevice = null;
  }

  // ============================ Global Functions =======================
  Future<void> sendData(String data) async {
    if (!hasConnection) return;

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(data + '\n')));
      await _connection!.output.allSent;
    } catch (_) {}
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

  StreamSubscription<List<double>>? _btDataSub;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initBluetooth();

    // === Listen data from MCU
    _btDataSub = BluetoothService.instance.dataStream.listen((numbers) {
      setState(() {
        latestValues = numbers;
      });
    });
  }

  // === Turn off bluetotooth connect when app off
  @override
  void dispose() {
    _btDataSub?.cancel();
    super.dispose();
  }

  // ========================== Local Functions ==========================
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
    setState(() {
      _devices = list
          .map((d) => BluetoothDiscoveryResult(device: d, rssi: 0))
          .toList();
    });
  }

  Future<void> _connect(BluetoothDevice d) async {
    try {
      await BluetoothService.instance.connect(d);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã kết nối ${d.name ?? d.address}')),
      );
      setState(() {});
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

  // =========================== Main Widget =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GardenScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (BluetoothService.instance.currentDevice != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Connected: ${BluetoothService.instance.currentDevice!.name ?? BluetoothService.instance.currentDevice!.address}',
                style: const TextStyle(
                  color: Color.fromARGB(255, 12, 1, 1),
                  backgroundColor: Color.fromARGB(66, 37, 209, 252),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _discovering ? null : _startDiscovery,
                child: Text(_discovering ? 'Scanning...' : 'Scan'),
              ),
              ElevatedButton(
                onPressed: _getBonded,
                child: const Text('Paired'),
              ),
              ElevatedButton(
                onPressed: _disconnect,
                child: const Text('Disconnect'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _devices.isEmpty
                ? const Center(child: Text('No devices'))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (_, i) {
                      final d = _devices[i].device;
                      final connected =
                          BluetoothService.instance.currentDevice?.address ==
                          d.address;
                      return ListTile(
                        title: Text(d.name ?? 'Unknown'),
                        subtitle: Text(d.address),
                        trailing: ElevatedButton(
                          onPressed: connected
                              ? _disconnect
                              : () => _connect(d),
                          child: Text(connected ? 'Disconnect' : 'Connect'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
