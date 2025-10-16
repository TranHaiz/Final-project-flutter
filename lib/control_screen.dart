// @file       control_screen.dart
// @copyright  Copyright (C) 2025 HAQ. All rights reserved.
// @license    This project is released under the <Your_License> License.
// @version    major.minor.patch
// @date       2025-10-12
// @author     Hai Tran
// @brief      Provides UI for controlling actuators (LEDs) using switches.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'garden_manager.dart';

const numbersActuator = 4;

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

class _ControlScreenState extends State<ControlScreen> {
  List<Actuator> actuators = [
    Actuator(name: 'Led 1'),
    Actuator(name: 'Led 2'),
    Actuator(name: 'Led 3'),
    Actuator(name: 'Led 4'),
  ];

  @override
  void initState() {
    super.initState();
    _loadActuatorStates();
  }

  Future<void> _loadActuatorStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < actuators.length; i++) {
        actuators[i].state = prefs.getBool('actuator_$i') ?? false;
      }
    });
  }

  Future<void> _saveActuatorState(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('actuator_$index', value);
  }

  Widget buildActuatorList() {
    List<Widget> actuatorWidgets = [];

    for (int i = 0; i < actuators.length; i++) {
      actuatorWidgets.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(
              Icons.lightbulb,
              color: actuators[i].state ? Colors.amber : Colors.grey,
            ),
            title: Text(actuators[i].name),
            trailing: Switch(
              value: actuators[i].state,
              onChanged: (value) {
                setState(() {
                  actuators[i].state = value;
                });
                _saveActuatorState(i, value);
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
    );
  }

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
