import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'login_screen.dart';

// ============================= Constants =============================
final List<String> plantTypes = ["Xoài", "Táo", "Sầu riêng"];
final Map<String, IconData> plantIcons = {
  "Xoài": Icons.eco,
  "Táo": Icons.apple,
  "Sầu riêng": Icons.forest,
};
final Map<String, Color> plantColors = {
  "Xoài": Colors.yellow.shade700,
  "Táo": Colors.redAccent,
  "Sầu riêng": Colors.green.shade700,
};
const int maxGardens = 4;

// =========================== Public Variables ========================
double temperature = 0;
double humidity = 0;
double lux = 0;

// ============================== Classes ==============================
class Plant {
  String name;
  Plant({required this.name});

  Map<String, dynamic> toJson() => {"name": name};
  factory Plant.fromJson(Map<String, dynamic> json) =>
      Plant(name: json["name"]);
}

class Garden {
  String name;
  List<Plant> plants;
  Garden({required this.name, List<Plant>? plants}) : plants = plants ?? [];

  Map<String, dynamic> toJson() => {
    "name": name,
    "plants": plants.map((p) => p.toJson()).toList(),
  };

  factory Garden.fromJson(Map<String, dynamic> json) => Garden(
    name: json["name"],
    plants:
        (json["plants"] as List<dynamic>?)
            ?.map((p) => Plant.fromJson(p))
            .toList() ??
        [],
  );
}

// ============================== Garden Screen ==============================
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  List<Garden> gardens = [];
  int selectedGarden = 0;

  // ========================== Local Functions ==========================
  Future<File> get localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/gardens.json");
  }

  Future<void> saveGardens() async {
    final file = await localFile;
    await file.writeAsString(
      jsonEncode(gardens.map((g) => g.toJson()).toList()),
    );
  }

  Future<void> loadGardens() async {
    final file = await localFile;
    if (await file.exists()) {
      final data = jsonDecode(await file.readAsString());
      setState(() {
        gardens = (data as List).map((g) => Garden.fromJson(g)).toList();
      });
    } else {
      setState(() => gardens = [Garden(name: "Vườn 1")]);
      saveGardens();
    }
  }

  // === Các thao tác quản lý dữ liệu ===
  void addGarden() {
    if (gardens.length >= maxGardens) return;
    setState(() {
      gardens.add(Garden(name: "Vườn ${gardens.length + 1}"));
      selectedGarden = gardens.length - 1;
    });
    saveGardens();
  }

  void deleteGarden(int index) {
    setState(() {
      gardens.removeAt(index);
      for (int i = 0; i < gardens.length; i++) {
        gardens[i].name = "Vườn ${i + 1}";
      }
      selectedGarden = gardens.isEmpty ? 0 : (index == 0 ? 0 : index - 1);
    });
    saveGardens();
  }

  void deletePlant(int index) {
    setState(() {
      gardens[selectedGarden].plants.removeAt(index);
    });
    saveGardens();
  }

  void addPlant() {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Chọn cây"),
        children: plantTypes.map((p) {
          return SimpleDialogOption(
            onPressed: () {
              setState(
                () => gardens[selectedGarden].plants.add(Plant(name: p)),
              );
              saveGardens();
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(
                  plantIcons[p] ?? Icons.local_florist,
                  color: plantColors[p] ?? Colors.green,
                ),
                const SizedBox(width: 8),
                Text(p),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void editEnvParams() {
    final tempController = TextEditingController(text: temperature.toString());
    final humidityController = TextEditingController(text: humidity.toString());
    final luxController = TextEditingController(text: lux.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Chỉnh thông số"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tempController,
              decoration: const InputDecoration(labelText: "Nhiệt độ"),
            ),
            TextField(
              controller: humidityController,
              decoration: const InputDecoration(labelText: "Độ ẩm"),
            ),
            TextField(
              controller: luxController,
              decoration: const InputDecoration(labelText: "Ánh sáng"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                temperature = double.tryParse(tempController.text) ?? 0;
                humidity = double.tryParse(humidityController.text) ?? 0;
                lux = double.tryParse(luxController.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadGardens();
  }

  // === Các Widget con ===
  Widget buildPlantCard(Plant plant, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          plantIcons[plant.name] ?? Icons.local_florist,
          color: plantColors[plant.name] ?? Colors.green,
        ),
        title: Text(plant.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => deletePlant(index),
        ),
      ),
    );
  }

  Widget buildEnvInfoCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.thermostat, color: Colors.orange),
            title: Text("Nhiệt độ: $temperature (ºC)"),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.blue),
            title: Text("Độ ẩm: $humidity (%)"),
          ),
          ListTile(
            leading: const Icon(
              Icons.brightness_low_outlined,
              color: Color.fromARGB(255, 240, 243, 73),
            ),
            title: Text("Cường độ sáng: $lux (lux)"),
          ),
        ],
      ),
    );
  }

  Widget buildPlantList(Garden garden) {
    return Expanded(
      child: ListView(
        children: [
          ...garden.plants.asMap().entries.map(
            (e) => buildPlantCard(e.value, e.key),
          ),
          Card(
            color: Colors.green[50],
            child: ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text("Thêm cây"),
              onTap: addPlant,
            ),
          ),
        ],
      ),
    );
  }

  // === Thanh điều hướng ===
  PreferredSizeWidget buildAppBar(Garden garden) {
    return AppBar(
      title: Row(
        children: [
          Text(garden.name),
          if (gardens.length > 1)
            GestureDetector(
              onTap: () => deleteGarden(selectedGarden),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 20, color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.settings), onPressed: editEnvParams),
        IconButton(
          icon: const Icon(
            Icons.output_outlined,
            color: Color.fromARGB(255, 240, 80, 69),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget buildBottomNav() {
    return BottomAppBar(
      child: Row(
        children: [
          for (int i = 0; i < gardens.length; i++)
            Expanded(
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => selectedGarden = i),
                  child: Text(
                    gardens[i].name,
                    style: TextStyle(
                      color: i == selectedGarden ? Colors.green : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          if (gardens.length < maxGardens)
            TextButton(onPressed: addGarden, child: const Text("➕ Thêm vườn")),
        ],
      ),
    );
  }

  // === Build UI chính ===
  @override
  Widget build(BuildContext context) {
    if (gardens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final garden = gardens[selectedGarden];

    return Scaffold(
      appBar: buildAppBar(garden),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            buildEnvInfoCard(),
            const SizedBox(height: 12),
            buildPlantList(garden),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNav(),
    );
  }
}
