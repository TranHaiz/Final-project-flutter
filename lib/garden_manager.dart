// lib/garden_manager.dart
// Màn hình quản lý vườn: hiển thị thông số môi trường, quản lý cây và vườn

/* Includes ----------------------------------------------------------- */
import 'package:flutter/material.dart';
import 'data_types.dart'; // Định nghĩa các lớp Garden, EnvData
import 'garden_storage.dart'; // Lưu trữ và tải dữ liệu vườn
import 'env_data_grid.dart'; // Grid hiển thị cây trong vườn
import 'garden_bottom_nav.dart'; // Bottom navigation hiển thị các vườn
import 'logic_screen.dart'; // Login screen để logout

/* Private variables -------------------------------------------------- */
final int maxGardens = 4; // Giới hạn số lượng vườn tối đa

// Các loại cây có thể thêm
final Map<String, String> envDataTypes = {
  "Xoài": "assets/xoai.png",
  "Táo": "assets/apple.png",
  "Sầu riêng": "assets/saurieng.png",
};

// Các thông số môi trường cần hiển thị
final List<String> envParamsTypes = [
  "Nhiệt độ (°C)",
  "Độ ẩm (%)",
  "Ánh sáng (lux)",
];

/* Function definitions ----------------------------------------------- */
class GardenManager extends StatefulWidget {
  const GardenManager({super.key});

  @override
  State<GardenManager> createState() => _GardenManagerState();
}

class _GardenManagerState extends State<GardenManager> {
  List<Garden> gardens = []; // Danh sách vườn
  int selectedIndex = 0; // Chỉ số vườn hiện tại

  @override
  void initState() {
    super.initState();
    _loadGardens(); // Load dữ liệu vườn khi mở màn hình
  }

  /* Private definitions ----------------------------------------------- */
  // Load dữ liệu vườn từ storage
  Future<void> _loadGardens() async {
    final data = await GardenStorage.loadGardens();
    setState(() {
      gardens = data;
      // Nếu chưa có giá trị môi trường thì mặc định 0
      for (var g in gardens) {
        for (var key in envParamsTypes) g.envParams.putIfAbsent(key, () => 0);
      }
    });
  }

  // Lưu dữ liệu vườn xuống storage
  Future<void> _saveGardens() async => await GardenStorage.saveGardens(gardens);

  // Thêm vườn mới
  void _addGarden() {
    if (gardens.length >= maxGardens) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Số lượng vườn đã đạt tối đa")),
      );
      return;
    }
    setState(() {
      gardens.add(
        Garden(
          name: "Vườn ${gardens.length + 1}",
          envParams: {for (var k in envParamsTypes) k: 0}, // Giá trị mặc định
        ),
      );
      selectedIndex = gardens.length - 1; // Chọn vườn mới thêm
    });
    _saveGardens();
  }

  // Xóa vườn
  void _removeGarden(int index) {
    if (gardens.length <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Phải có ít nhất 1 vườn")));
      return;
    }
    setState(() {
      gardens.removeAt(index);
      if (selectedIndex >= gardens.length) selectedIndex = gardens.length - 1;
      // Cập nhật lại tên vườn theo thứ tự
      for (int i = 0; i < gardens.length; i++)
        gardens[i].name = "Vườn ${i + 1}";
    });
    _saveGardens();
  }

  // Thêm cây vào vườn
  void _addEnvData(EnvData envData) {
    setState(() => gardens[selectedIndex].envDatas.add(envData));
    _saveGardens();
  }

  // Xóa cây trong vườn
  void _deleteEnvData(int index) {
    setState(() => gardens[selectedIndex].envDatas.removeAt(index));
    _saveGardens();
  }

  // Cập nhật thông số môi trường từ dữ liệu bên ngoài (ESP / Bluetooth)
  void updateEnvParams(Map<String, double> newData) {
    setState(() {
      final garden = gardens[selectedIndex];
      for (var key in envParamsTypes) {
        garden.envParams[key] = newData[key] ?? 0; // Nếu chưa nhận dữ liệu = 0
      }
    });
    _saveGardens();
  }

  /* Widget definitions ----------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    if (gardens.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final garden = gardens[selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(garden.name),
            const SizedBox(width: 6),
            // Nút xóa vườn (chỉ hiện nếu >1 vườn)
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
          // Nút logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hiển thị thông số môi trường
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: envParamsTypes.map((key) {
                final val = garden.envParams[key] ?? 0;
                IconData icon;
                Color color;
                if (key.contains("Nhiệt độ")) {
                  icon = Icons.thermostat;
                  color = Colors.orange;
                } else if (key.contains("Độ ẩm")) {
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
                            key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$val",
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
          // Hiển thị danh sách cây
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
      // Bottom navigation: hiển thị các vườn, thêm vườn
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
