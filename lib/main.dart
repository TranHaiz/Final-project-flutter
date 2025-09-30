import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class EnvData {
  String name;
  String imagePath;

  EnvData({required this.name, required this.imagePath});

  Map<String, dynamic> toJson() => {
        "name": name,
        "imagePath": imagePath,
      };

  factory EnvData.fromJson(Map<String, dynamic> json) {
    return EnvData(
      name: json["name"],
      imagePath: json["imagePath"],
    );
  }
}

class Garden {
  String name;
  List<EnvData> envDatas;
  Map<String, double> envParams;

  Garden({
    required this.name,
    List<EnvData>? envDatas,
    Map<String, double>? envParams,
  })  : envDatas = envDatas ?? [],
        envParams = envParams ?? {};

  Map<String, dynamic> toJson() => {
        "name": name,
        "envDatas": envDatas.map((p) => p.toJson()).toList(),
        "envParams": envParams,
      };

  factory Garden.fromJson(Map<String, dynamic> json) {
    return Garden(
      name: json["name"],
      envDatas: (json["envDatas"] as List<dynamic>?)
              ?.map((p) => EnvData.fromJson(p))
              .toList() ??
          [],
      envParams: Map<String, double>.from(json["envParams"] ?? {}),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Vườn',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const GardenManager(),
    );
  }
}

class GardenManager extends StatefulWidget {
  const GardenManager({super.key});

  @override
  State<GardenManager> createState() => _GardenManagerState();
}

class _GardenManagerState extends State<GardenManager> {
  List<Garden> gardens = [];
  int _selectedIndex = 0;
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

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/gardens.json");
  }

  Future<void> _saveGardens() async {
    try {
      final file = await _localFile;
      final jsonData = jsonEncode(gardens.map((g) => g.toJson()).toList());
      await file.writeAsString(jsonData);
    } catch (_) {}
  }

  Future<void> _loadGardens() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        final List<dynamic> data = jsonDecode(jsonData);
        setState(() {
          gardens = data.map((g) => Garden.fromJson(g)).toList();
        });
      } else {
        setState(() {
          gardens = [Garden(name: "Vườn 1")];
        });
        await _saveGardens();
      }
    } catch (_) {
      setState(() {
        gardens = [Garden(name: "Vườn 1")];
      });
      await _saveGardens();
    }
  }

  void _addGarden() {
    if (gardens.length < maxGardens) {
      setState(() {
        gardens.add(Garden(name: "Vườn ${gardens.length + 1}"));
        _selectedIndex = gardens.length - 1;
      });
      _saveGardens();
    }
  }

  void _deleteGarden(int index) {
    if (gardens.length > 1) {
      setState(() {
        gardens.removeAt(index);
        if (_selectedIndex >= gardens.length) {
          _selectedIndex = gardens.length - 1;
        }
      });
      _saveGardens();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phải có ít nhất 1 vườn")),
      );
    }
  }

  void _deleteEnvData(int envDataIndex) {
    setState(() {
      gardens[_selectedIndex].envDatas.removeAt(envDataIndex);
    });
    _saveGardens();
  }

  void _addEnvData() {
    if (gardens[_selectedIndex].envDatas.length < 10) {
      showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text("Chọn loại cây"),
            children: envDataTypes.entries.map((entry) {
              return SimpleDialogOption(
                onPressed: () {
                  setState(() {
                    gardens[_selectedIndex].envDatas.add(
                          EnvData(name: entry.key, imagePath: entry.value),
                        );
                  });
                  _saveGardens();
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    Image.asset(entry.value, width: 40, height: 40),
                    const SizedBox(width: 10),
                    Text(entry.key),
                  ],
                ),
              );
            }).toList(),
          );
        },
      );
    }
  }

  void _editEnvParams() {
    final garden = gardens[_selectedIndex];
    showDialog(
      context: context,
      builder: (context) {
        final controllers = {
          for (var key in envParamsTypes)
            key: TextEditingController(
                text: garden.envParams[key]?.toString() ?? "")
        };
        return AlertDialog(
          title: const Text("Chỉnh thông số môi trường"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: envParamsTypes.map((param) {
                return TextField(
                  controller: controllers[param],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: param),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  for (var param in envParamsTypes) {
                    final val = double.tryParse(controllers[param]!.text);
                    if (val != null) {
                      garden.envParams[param] = val;
                    }
                  }
                });
                _saveGardens();
                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gardens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final currentGarden = gardens[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(currentGarden.name)),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _deleteGarden(_selectedIndex),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.thermostat),
            onPressed: _editEnvParams,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset("assets/garden.png", fit: BoxFit.cover)),
          Column(
            children: [
              if (currentGarden.envParams.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: currentGarden.envParams.entries.map((e) {
                      IconData icon;
                      Color color;

                      if (e.key.contains("Nhiệt độ")) {
                        icon = Icons.thermostat;
                        color = Colors.orange;
                      } else if (e.key.contains("Độ ẩm")) {
                        icon = Icons.water_drop;
                        color = Colors.blue;
                      } else if (e.key.contains("Ánh sáng")) {
                        icon = Icons.wb_sunny;
                        color = Colors.yellow.shade700;
                      } else {
                        icon = Icons.info;
                        color = Colors.green;
                      }

                      return Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 32, color: color),
                                const SizedBox(height: 8),
                                Text(
                                  e.key,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${e.value}",
                                  style: TextStyle(
                                    fontSize: 18,
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
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: currentGarden.envDatas.length +
                      (currentGarden.envDatas.length < 10 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == currentGarden.envDatas.length &&
                        currentGarden.envDatas.length < 10) {
                      return GestureDetector(
                        onTap: _addEnvData,
                        child: Card(
                          color: Colors.green[50],
                          child: const Center(child: Text("➕ Thêm cây")),
                        ),
                      );
                    } else {
                      final envData = currentGarden.envDatas[index];
                      return Card(
                        elevation: 2,
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(envData.imagePath,
                                      width: 60, height: 60),
                                  const SizedBox(height: 8),
                                  Text(envData.name),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _deleteEnvData(index),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index < gardens.length) {
            setState(() {
              _selectedIndex = index;
            });
          } else if (index == gardens.length && gardens.length < maxGardens) {
            _addGarden();
          }
        },
        items: [
          ...gardens.map(
            (g) => BottomNavigationBarItem(
              icon: const Icon(Icons.grass),
              label: g.name,
            ),
          ),
          if (gardens.length < maxGardens)
            const BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: "Thêm vườn",
            ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}