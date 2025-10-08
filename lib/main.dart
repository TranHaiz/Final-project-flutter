import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

// Dữ liệu cây
class Plant {
  String name;
  Plant({required this.name});

  Map<String, dynamic> toJson() => {"name": name};
  factory Plant.fromJson(Map<String, dynamic> json) =>
      Plant(name: json["name"]);
}

// Dữ liệu vườn
class Garden {
  String name;
  List<Plant> plants;
  Map<String, double> envParams; // Ví dụ: nhiệt độ, độ ẩm

  Garden({
    required this.name,
    List<Plant>? plants,
    Map<String, double>? envParams,
  }) : plants = plants ?? [],
       envParams = envParams ?? {};

  Map<String, dynamic> toJson() => {
    "name": name,
    "plants": plants.map((p) => p.toJson()).toList(),
    "envParams": envParams,
  };

  factory Garden.fromJson(Map<String, dynamic> json) => Garden(
    name: json["name"],
    plants:
        (json["plants"] as List<dynamic>?)
            ?.map((p) => Plant.fromJson(p))
            .toList() ??
        [],
    envParams: Map<String, double>.from(json["envParams"] ?? {}),
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
      setState(() {
        gardens = [Garden(name: "Vườn 1")];
      });
      saveGardens();
    }
  }

  void addGarden() {
    setState(() {
      gardens.add(Garden(name: "Vườn ${gardens.length + 1}"));
      selectedGarden = gardens.length - 1;
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
                  setState(() {
                    gardens[selectedGarden].plants.add(Plant(name: p));
                  });
                  saveGardens();
                  Navigator.pop(context);
                },
                child: Text(p),
              ),
            )
            .toList(),
      ),
    );
  }

  void editEnvParams() {
    final garden = gardens[selectedGarden];
    final tempController = TextEditingController(
      text: garden.envParams["Nhiệt độ"]?.toString() ?? "",
    );
    final humidityController = TextEditingController(
      text: garden.envParams["Độ ẩm"]?.toString() ?? "",
    );

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
                garden.envParams["Nhiệt độ"] =
                    double.tryParse(tempController.text) ?? 0;
                garden.envParams["Độ ẩm"] =
                    double.tryParse(humidityController.text) ?? 0;
              });
              saveGardens();
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          ),
        ],
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
        title: Text(garden.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: editEnvParams,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Hiển thị thông số môi trường
          if (garden.envParams.isNotEmpty)
            ...garden.envParams.entries.map(
              (e) => ListTile(title: Text("${e.key}: ${e.value}")),
            ),
          const SizedBox(height: 12),
          // Hiển thị danh sách cây
          ...garden.plants.map(
            (p) => ListTile(
              title: Text(p.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => deletePlant(garden.plants.indexOf(p)),
              ),
            ),
          ),
          // Nút thêm cây
          ListTile(title: const Text("➕ Thêm cây"), onTap: addPlant),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            for (int i = 0; i < gardens.length; i++)
              Expanded(
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
            TextButton(onPressed: addGarden, child: const Text("➕ Thêm vườn")),
          ],
        ),
      ),
    );
  }
}
