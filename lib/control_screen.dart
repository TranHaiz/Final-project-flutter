// @file       control_screen.dart
// @copyright  Copyright (C) 2025 HAQ. All rights reserved.
// @license    This project is released under the <Your_License> License.
// @version    major.minor.patch
// @date       2025-10-12
// @author     Hai Tran
// @brief      Provides UI for controlling actuators (LEDs) using switches.
// ============================== Imports ==============================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'garden_manager.dart';
import 'bluetooth.dart';

// ============================= Constants =============================
const numbersActuator = 4;

// ============================== Classes ==============================
class Actuator {
  bool state;
  String name;

  Actuator({required this.name, this.state = false});
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with WidgetsBindingObserver {
  List<Actuator> actuators = [
    Actuator(name: 'Led 1'),
    Actuator(name: 'Led 2'),
    Actuator(name: 'Led 3'),
    Actuator(name: 'Led 4'),
  ];

  // =========================== Private Variables =======================
  bool _isLoading = true;

  // ========================== Local Functions ==========================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadActuatorStates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Lưu trạng thái khi thoát màn hình
    _saveAllActuatorStates();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lưu trạng thái khi app chuyển sang background hoặc bị tắt
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveAllActuatorStates();
    }
  }

  // Load trạng thái đã lưu của tất cả actuators
  Future<void> _loadActuatorStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        for (int i = 0; i < actuators.length; i++) {
          actuators[i].state = prefs.getBool('actuator_$i') ?? false;
        }
        _isLoading = false;
      });

      // Đồng bộ trạng thái với thiết bị sau khi load
      _syncStatesWithDevice();
    } catch (e) {
      debugPrint('Error loading actuator states: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Lưu trạng thái của một actuator cụ thể
  Future<void> _saveActuatorState(int index, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('actuator_$index', value);
      debugPrint('Saved actuator $index state: $value');
    } catch (e) {
      debugPrint('Error saving actuator state: $e');
    }
  }

  // Lưu trạng thái của tất cả actuators
  Future<void> _saveAllActuatorStates() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < actuators.length; i++) {
      await prefs.setBool('actuator_$i', actuators[i].state);
    }
    debugPrint('Saved all actuator states');
  }

  // Đồng bộ trạng thái với thiết bị Bluetooth
  Future<void> _syncStatesWithDevice() async {
    try {
      final command =
          "${actuators[0].state},${actuators[1].state},"
          "${actuators[2].state},${actuators[3].state}\n";
      await BluetoothService.instance.sendData(command);
      debugPrint('Synced states with device: $command');
    } catch (e) {
      debugPrint('Error syncing with device: $e');
    }
  }

  // Xóa tất cả trạng thái đã lưu (để test hoặc reset)
  Future<void> _clearAllStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < actuators.length; i++) {
        await prefs.remove('actuator_$i');
      }
      setState(() {
        for (var actuator in actuators) {
          actuator.state = false;
        }
      });
      _syncStatesWithDevice();
    } catch (e) {
      debugPrint('Error clearing states: $e');
    }
  }

  // =========================== Sub Widgets =============================
  Widget buildActuatorList() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    List<Widget> actuatorWidgets = [];

    // === Build Actutors
    for (int i = 0; i < actuators.length; i++) {
      actuatorWidgets.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.lightbulb,
              color: actuators[i].state ? Colors.amber : Colors.grey,
              size: 32,
            ),
            title: Text(
              actuators[i].name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              actuators[i].state ? 'Đang bật' : 'Đang tắt',
              style: TextStyle(
                fontSize: 12,
                color: actuators[i].state ? Colors.green : Colors.grey,
              ),
            ),
            trailing: Switch(
              value: actuators[i].state,
              activeColor: Colors.amber,
              onChanged: (_) async {
                setState(() {
                  actuators[i].state = !actuators[i].state;
                });

                // Gửi lệnh đến thiết bị
                final command = "$i+${actuators[i].state}";
                await BluetoothService.instance.sendData(command);

                // Lưu trạng thái
                await _saveActuatorState(i, actuators[i].state);
              },
            ),
          ),
        ),
      );
    }

    return Expanded(child: ListView(children: actuatorWidgets));
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      title: const Text('Điều khiển thiết bị'),
      actions: [
        // Nút đồng bộ
        IconButton(
          icon: const Icon(
            Icons.sync,
            color: Color.fromARGB(255, 10, 201, 235),
          ),
          tooltip: 'Đồng bộ với thiết bị',
          onPressed: () async {
            await _syncStatesWithDevice();
          },
        ),
        // Nút reset (tùy chọn)
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.orange),
          tooltip: 'Reset tất cả LED',
          onPressed: () {
            _clearAllStates();
          },
        ),
        // Nút thoát
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          tooltip: 'Thoát',
          onPressed: () {
            // Lưu trạng thái trước khi thoát
            _saveAllActuatorStates();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GardenScreen()),
            );
          },
        ),
      ],
    );
  }

  // =========================== Main Widget =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [const SizedBox(height: 12), buildActuatorList()],
        ),
      ),
    );
  }
}
