import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';

class BluetoothService {
  static final BluetoothService instance = BluetoothService._internal();
  BluetoothService._internal();

  BluetoothConnection? _connection;
  final List<void Function(String)> _listeners = [];

  void setConnection(BluetoothConnection c) {
    _connection = c;
  }

  bool get isConnected => _connection?.isConnected ?? false;

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  Future<void> send(String data) async {
    if (_connection?.isConnected ?? false) {
      _connection!.output.add(Uint8List.fromList(data.codeUnits));
      await _connection!.output.allSent;
    }
  }

  void onReceive(String msg) {
    for (var f in _listeners) {
      f(msg);
    }
  }

  void addListener(void Function(String) callback) {
    _listeners.add(callback);
  }

  void removeListener(void Function(String) callback) {
    _listeners.remove(callback);
  }
}
