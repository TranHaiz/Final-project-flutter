// lib/garden_manager.dart
// Màn hình quản lý vườn: hiển thị thông số môi trường, quản lý cây và vườn

import 'package:flutter/material.dart';
import 'data_types.dart';
import 'garden_storage.dart';
import 'env_params_editor.dart';
import 'env_data_grid.dart';
import 'garden_bottom_nav.dart';
import 'logic_screen.dart'; // để điều hướng quay lại login

class GardenManager extends StatefulWidget {
  const GardenManager({super.key});

  @override
  State<GardenManager> createState() => _GardenManagerState();
}

class _GardenManagerState extends State<GardenManager> {
  List<Garden> gardens = [];
  int selectedIndex = 0;
  final int maxGardens = 4;

  final Map<String, String> envDataTypes = {
    "Xoài": "assets/xoai.png",
    "Táo": "assets/apple.png",
    "Sầu riêng": "assets/saurieng.png",
  };

  final List<String> envParamsTypes = [
    "Nhiệt độ (°C)",
    "Độ ẩm (%)",
    "Ánh sáng (lux)"
  ];

  @override
  void initState() {
    super.initState();
    _loadGardens();
  }

  Future<void> _loadGardens() async {
    final data = await GardenStorage.loadGardens();
    setState(() => gardens = data);
  }

  Future<void> _saveGardens() async {
    await GardenStorage.saveGardens(gardens);
  }

  void _addGarden() {
    if (gardens.length >= maxGardens) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Số lượng vườn đã đạt tối đa")),
      );
      return;
    }
    setState(() {
      gardens.add(Garden(name: "Vườn ${gardens.length + 1}"));
      selectedIndex = gardens.length - 1;
    });
    _saveGardens();
  }

  void _removeGarden(int index) {
    if (gardens.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phải có ít nhất 1 vườn")),
      );
      return;
    }
    setState(() {
      gardens.removeAt(index);
      if (selectedIndex >= gardens.length) {
        selectedIndex = gardens.length - 1;
      }
    });
    _saveGardens();
  }

  void _addEnvData(EnvData envData) {
    setState(() {
      gardens[selectedIndex].envDatas.add(envData);
    });
    _saveGardens();
  }

  void _deleteEnvData(int index) {
    setState(() {
      gardens[selectedIndex].envDatas.removeAt(index);
    });
    _saveGardens();
  }

  void _editEnvParams() {
    final garden = gardens[selectedIndex];
    showDialog(
      context: context,
      builder: (context) => EnvParamsEditor(
        garden: garden,
        envParamsTypes: envParamsTypes,
        onSave: (newParams) {
          setState(() {
            garden.envParams = newParams;
          });
          _saveGardens();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gardens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final garden = gardens[selectedIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        title: Row(
          children: [
            Text(garden.name),
            const SizedBox(width: 6),
            if (gardens.length > 1)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () => _removeGarden(selectedIndex),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _editEnvParams,
          ),
        ],
      ),
      body: Column(
        children: [
          if (garden.envParams.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: garden.envParams.entries.map((e) {
                  IconData icon;
                  Color color;
                  if (e.key.contains("Nhiệt độ")) {
                    icon = Icons.thermostat;
                    color = Colors.orange;
                  } else if (e.key.contains("Độ ẩm")) {
                    icon = Icons.water_drop;
                    color = Colors.blue;
                  } else {
                    icon = Icons.wb_sunny;
                    color = Colors.yellow.shade700;
                  }
                  return Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Icon(icon, size: 28, color: color),
                            const SizedBox(height: 6),
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${e.value}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: EnvDataGrid(
              envDatas: garden.envDatas,
              envDataTypes: envDataTypes,
              onAdd: _addEnvData,
              onDelete: _deleteEnvData,
            ),
          ),
        ],
      ),
      bottomNavigationBar: GardenBottomNav(
        gardens: gardens,
        selectedIndex: selectedIndex,
        maxGardens: maxGardens,
        onSelect: (i) => setState(() => selectedIndex = i),
        onAdd: _addGarden,
      ),
    );
  }
}
