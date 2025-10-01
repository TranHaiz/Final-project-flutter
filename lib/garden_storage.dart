import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'data_types.dart';

class GardenStorage {
  static Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/gardens.json");
  }

  static Future<void> saveGardens(List<Garden> gardens) async {
    final file = await _localFile;
    final jsonData = jsonEncode(gardens.map((g) => g.toJson()).toList());
    await file.writeAsString(jsonData);
  }

  static Future<List<Garden>> loadGardens() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonData = await file.readAsString();
        final List<dynamic> data = jsonDecode(jsonData);
        return data.map((g) => Garden.fromJson(g)).toList();
      }
    } catch (_) {}
    return [Garden(name: "Vườn 1")];
  }
}
