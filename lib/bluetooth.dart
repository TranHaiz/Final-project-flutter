import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_service.dart';
import 'garden_manager.dart';

Future<void> _checkPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.location,
  ].request();
}

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

      c.input?.listen((data) {
        final msg = String.fromCharCodes(data);
        BluetoothService.instance.onReceive(msg);
      });

      setState(() {}); // Cập nhật UI
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
    final connected = BluetoothService.instance.isConnected(d);
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
                onPressed: !BluetoothService.instance.hasConnection
                    ? () => _connect(d)
                    : null,
                child: const Text('Kết nối'),
              ),
      ),
    );
  }

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
            icon: const Icon(Icons.logout_outlined, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GardenScreen()),
              );
            },
          ),
        ],
      ),
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
