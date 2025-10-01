// Màn hình quản lý vườn: hiển thị EnvDataGrid + chỉnh thông số môi trường + bottom navigation

import 'package:flutter/material.dart';
import 'data_types.dart';
import 'garden_storage.dart';
import 'env_data_grid.dart';
import 'env_params_editor.dart';
import 'garden_bottom_nav.dart';

class GardenManager extends StatefulWidget {
  const GardenManager({super.key});

  @override
  State<GardenManager> createState() => _GardenManagerState();
}

class _GardenManagerState extends State<GardenManager> {
  List<Garden> gardens = [];
  int selectedIndex = 0;
  final int maxGardens = 3;

  final Map<String, String> envDataTypes = {
    "Cây Cam": "assets/images/cam.png",
    "Cây Táo": "assets/images/tao.png",
    "Cây Xoài": "assets/images/xoai.png",
    "Cây Bưởi": "assets/images/buoi.png",
  };

  final List<String> envParamsTypes = ["Nhiệt độ", "Độ ẩm", "Ánh sáng"];

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
    if (gardens.length >= maxGardens) return;
    setState(() {
      gardens.add(Garden(name: "Vườn ${gardens.length + 1}"));
      selectedIndex = gardens.length - 1;
    });
    _saveGardens();
  }

  void _removeGarden(int index) {
    setState(() {
      gardens.removeAt(index);
      if (selectedIndex >= gardens.length) {
        selectedIndex = gardens.isEmpty ? 0 : gardens.length - 1;
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
    showDialog(
      context: context,
      builder: (ctx) => EnvParamsEditor(
        garden: gardens[selectedIndex],
        envParamsTypes: envParamsTypes,
        onSave: (newParams) {
          setState(() {
            gardens[selectedIndex].envParams = newParams;
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
        title: Text("Quản lý: ${garden.name}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _editEnvParams,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeGarden(selectedIndex),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: EnvDataGrid(
              envDatas: garden.envDatas,
              envDataTypes: envDataTypes,
              onAdd: _addEnvData,
              onDelete: _deleteEnvData,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: garden.envParams.entries.map((e) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.thermostat, color: Colors.green),
                    title: Text(e.key),
                    trailing: Text("${e.value}"),
                  ),
                );
              }).toList(),
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
