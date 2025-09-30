// main.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

/// Lớp Cây
class Plant {
  final String name;
  final String imagePath;

  Plant({required this.name, required this.imagePath});

  Map<String, dynamic> toJson() => {
    "name": name,
    "imagePath": imagePath,
  };

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      name: json["name"],
      imagePath: json["imagePath"],
    );
  }
}

/// Lớp Vườn
class Garden {
  String name;
  List<Plant> plants;

  Garden({required this.name, this.plants = const []});

  Map<String, dynamic> toJson() => {
    "name": name,
    "plants": plants.map((p) => p.toJson()).toList(),
  };

  factory Garden.fromJson(Map<String, dynamic> json) {
    return Garden(
      name: json["name"],
      plants: (json["plants"] as List<dynamic>)
          .map((p) => Plant.fromJson(p))
          .toList(),
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

  /// Danh sách loại cây có sẵn (ảnh từ assets)
  final Map<String, String> plantTypes = {
    "Xoài": "assets/xoai.png",
    "Táo": "assets/apple.png",
    "Sầu riêng": "assets/saurieng.png",
  };

  @override
  void initState() {
    super.initState();
    _loadGardens();
  }

  /// File lưu trữ
  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/gardens.json");
  }

  /// Sắp xếp gardens theo số trong tên "Vườn N" tăng dần.
  /// Giữ selection (nếu có) bằng tên trước khi sắp xếp.
  void _sortGardensKeepSelection() {
    String? selectedName;
    if (gardens.isNotEmpty && _selectedIndex >= 0 && _selectedIndex < gardens.length) {
      selectedName = gardens[_selectedIndex].name;
    }

    int extractNumber(String name) {
      final m = RegExp(r'\d+').firstMatch(name);
      if (m != null) {
        return int.tryParse(m.group(0) ?? '') ?? 0;
      }
      return 0;
    }

    gardens.sort((a, b) {
      final na = extractNumber(a.name);
      final nb = extractNumber(b.name);
      if (na != nb) return na.compareTo(nb);
      return a.name.compareTo(b.name);
    });

    // restore selected index if possible
    if (selectedName != null) {
      final newIndex = gardens.indexWhere((g) => g.name == selectedName);
      _selectedIndex = newIndex >= 0 ? newIndex : 0;
    } else {
      _selectedIndex = (_selectedIndex < gardens.length) ? _selectedIndex : 0;
    }
  }

  /// Lưu dữ liệu vào file
  Future<void> _saveGardens() async {
    try {
      final file = await _localFile;
      _sortGardensKeepSelection();
      final jsonData = jsonEncode(gardens.map((g) => g.toJson()).toList());
      await file.writeAsString(jsonData);
    } catch (e) {
      // handle error if needed
    }
  }

  /// Tải dữ liệu từ file
  Future<void> _loadGardens() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        final List<dynamic> data = jsonDecode(jsonData);
        setState(() {
          gardens = data.map((g) => Garden.fromJson(g)).toList();
        });
        _sortGardensKeepSelection();
      } else {
        setState(() {
          gardens = [Garden(name: "Vườn 1", plants: [])];
          _selectedIndex = 0;
        });
        await _saveGardens();
      }
    } catch (e) {
      setState(() {
        gardens = [Garden(name: "Vườn 1", plants: [])];
        _selectedIndex = 0;
      });
      await _saveGardens();
    }
  }

  /// Tìm số nhỏ nhất chưa dùng (1..)
  int _findSmallestUnusedIndex() {
    final used = gardens.map((g) {
      final m = RegExp(r'\d+').firstMatch(g.name);
      return m != null ? int.tryParse(m.group(0) ?? '') ?? 0 : 0;
    }).toSet();

    int i = 1;
    while (used.contains(i)) {
      i++;
    }
    return i;
  }

  /// Thêm vườn (dùng số nhỏ nhất chưa dùng)
  void _addGarden() {
    if (gardens.length < 4) {
      final nextIndex = _findSmallestUnusedIndex();
      setState(() {
        gardens.add(Garden(name: "Vườn $nextIndex", plants: []));
        // set selection to that garden after sort
      });
      _saveGardens();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tối đa 4 vườn")),
      );
    }
  }

  /// Xóa vườn
  void _deleteGarden(int index) {
    if (gardens.length > 1) {
      final wasSelectedName = gardens[_selectedIndex].name;
      setState(() {
        gardens.removeAt(index);
        // Try to keep selection consistent: if deleted one was selected, move selection to nearest index
        if (gardens.isEmpty) {
          _selectedIndex = 0;
        } else if (_selectedIndex >= gardens.length) {
          _selectedIndex = gardens.length - 1;
        } else {
          // keep same index if possible
        }
      });
      _saveGardens();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phải có ít nhất 1 vườn")),
      );
    }
  }

  /// Dialog quản lý vườn
  void _showGardenDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Quản lý vườn"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (gardens.length < 4)
                  ElevatedButton(
                    onPressed: _addGarden,
                    child: const Text("➕ Thêm vườn"),
                  ),
                const SizedBox(height: 8),
                ...gardens.asMap().entries.map((entry) {
                  final index = entry.key;
                  final garden = entry.value;
                  return ListTile(
                    leading: Image.asset("assets/garden.png", width: 40, height: 40),
                    title: Text(garden.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteGarden(index);
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Thêm cây (chọn loại từ assets)
  void _addPlant() {
    if (gardens[_selectedIndex].plants.length < 10) {
      showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text("Chọn loại cây"),
            children: plantTypes.entries.map((entry) {
              return SimpleDialogOption(
                onPressed: () {
                  setState(() {
                    gardens[_selectedIndex].plants.add(
                      Plant(name: entry.key, imagePath: entry.value),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mỗi vườn tối đa 10 cây")),
      );
    }
  }

  /// Xóa cây
  void _deletePlant(int plantIndex) {
    setState(() {
      gardens[_selectedIndex].plants.removeAt(plantIndex);
    });
    _saveGardens();
  }

  @override
  Widget build(BuildContext context) {
    if (gardens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final currentGarden = gardens[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGarden.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            onPressed: _showGardenDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset("assets/garden.png", fit: BoxFit.cover),
          ),
          // Grid of plants
          GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: currentGarden.plants.length +
                (currentGarden.plants.length < 10 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == currentGarden.plants.length &&
                  currentGarden.plants.length < 10) {
                return GestureDetector(
                  onTap: _addPlant,
                  child: Card(
                    color: Colors.green[50],
                    child: const Center(child: Text("➕ Thêm cây")),
                  ),
                );
              } else {
                final plant = currentGarden.plants[index];
                return Card(
                  elevation: 2,
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(plant.imagePath, width: 60, height: 60, fit: BoxFit.contain),
                            const SizedBox(height: 8),
                            Text(plant.name),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePlant(index),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == gardens.length) {
            _showGardenDialog();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: [
          ...gardens.map((g) => BottomNavigationBarItem(icon: const Icon(Icons.grass), label: g.name)),
          if (gardens.length < 4) const BottomNavigationBarItem(icon: Icon(Icons.add), label: "Thêm"),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
