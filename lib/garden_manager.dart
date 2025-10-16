import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'login_screen.dart';
import 'bluetooth.dart';

final List<String> plantTypes = ["Xoài", "Táo", "Sầu riêng"];
final Map<String, IconData> plantIcons = {
  "Xoài": Icons.eco,
  "Táo": Icons.apple,
  "Sầu riêng": Icons.forest,
};
final Map<String, Color> plantColors = {
  "Xoài": Colors.yellow,
  "Táo": Colors.redAccent,
  "Sầu riêng": Colors.green,
};

const int maxGardens = 4;

List<double> temperature = List.filled(maxGardens, 0.0);
List<double> humidity = List.filled(maxGardens, 0.0);
List<double> lux = List.filled(maxGardens, 0.0);

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
        (json["plants"] as List?)?.map((p) => Plant.fromJson(p)).toList() ?? [],
  );
}

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  List<Garden> gardens = [];
  int selectedGarden = 0;
  StreamSubscription? _btStreamSub;

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

  @override
  void initState() {
    super.initState();
    loadGardens();

    _btStreamSub = BluetoothService.instance.dataStream.listen((numbers) {
      if (numbers is List && numbers.isNotEmpty) {
        setState(() {
          for (int i = 0; i < maxGardens; i++) {
            int base = i * 3;
            if (numbers.length >= base + 3) {
              temperature[i] = (numbers[base] as num).toDouble();
              humidity[i] = (numbers[base + 1] as num).toDouble();
              lux[i] = (numbers[base + 2] as num).toDouble();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _btStreamSub?.cancel();
    super.dispose();
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
    if (gardens.length == 1) return;
    setState(() {
      gardens.removeAt(index);
      for (int i = 0; i < gardens.length; i++) {
        gardens[i].name = "Vườn ${i + 1}";
      }
      selectedGarden = selectedGarden > 0 ? selectedGarden - 1 : 0;
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
              setState(() {
                gardens[selectedGarden].plants.add(Plant(name: p));
              });
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

  Widget buildEnvInfoCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.thermostat, color: Colors.orange),
            title: Text(
              "Nhiệt độ: ${temperature[selectedGarden].toStringAsFixed(1)} °C",
            ),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.blue),
            title: Text(
              "Độ ẩm: ${humidity[selectedGarden].toStringAsFixed(1)} %",
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.brightness_low_outlined,
              color: Colors.amber,
            ),
            title: Text(
              "Ánh sáng: ${lux[selectedGarden].toStringAsFixed(1)} lux",
            ),
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
            (e) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  plantIcons[e.value.name] ?? Icons.local_florist,
                  color: plantColors[e.value.name] ?? Colors.green,
                ),
                title: Text(e.value.name),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => deletePlant(e.key),
                ),
              ),
            ),
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

  PreferredSizeWidget buildAppBar(Garden garden) {
    return AppBar(
      title: Text(garden.name),
      actions: [
        IconButton(
          icon: const Icon(Icons.bluetooth_connected, color: Colors.blue),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BluetoothScanPage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => deleteGarden(selectedGarden),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      ],
    );
  }

  Widget buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: selectedGarden,
      onTap: (index) {
        if (index == gardens.length && gardens.length < maxGardens) {
          addGarden();
        } else if (index < gardens.length) {
          setState(() => selectedGarden = index);
        }
      },
      items: [
        for (int i = 0; i < gardens.length; i++)
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_florist_outlined),
            label: gardens[i].name,
          ),
        if (gardens.length < maxGardens)
          const BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Thêm vườn',
          ),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }

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
