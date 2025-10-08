import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

// === Biến toàn cục cho thông số môi trường ===
double temperature = 0;
double humidity = 0;

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
            (json["plants"] as List<dynamic>?)?.map((p) => Plant.fromJson(p)).toList() ?? [],
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Vườn',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const GardenScreen(),
    );
  }
}

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  List<Garden> gardens = [];
  int selectedGarden = 0;
  final List<String> plantTypes = ["Xoài", "Táo", "Sầu riêng"];
  final int maxGardens = 4;

  @override
  void initState() {
    super.initState();
    loadGardens();
  }

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
        children: plantTypes
            .map(
              (p) => SimpleDialogOption(
                onPressed: () {
                  setState(
                    () => gardens[selectedGarden].plants.add(Plant(name: p)),
                  );
                  saveGardens();
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.local_florist, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(p),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void editEnvParams() {
    final tempController = TextEditingController(text: temperature.toString());
    final humidityController = TextEditingController(text: humidity.toString());

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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                temperature = double.tryParse(tempController.text) ?? 0;
                humidity = double.tryParse(humidityController.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Widget buildPlantCard(Plant plant, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.local_florist, color: Colors.green),
        title: Text(plant.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => deletePlant(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gardens.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final garden = gardens[selectedGarden];

    return Scaffold(
      appBar: AppBar(
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: editEnvParams,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.thermostat, color: Colors.orange),
                    title: Text("Nhiệt độ: $temperature"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.water_drop, color: Colors.blue),
                    title: Text("Độ ẩm: $humidity"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
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
              TextButton(
                onPressed: addGarden,
                child: const Text("➕ Thêm vườn"),
              ),
          ],
        ),
      ),
    );
  }
}
