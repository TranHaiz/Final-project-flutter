import 'package:flutter/material.dart';
import 'data_types.dart';

class EnvDataGrid extends StatelessWidget {
  final List<EnvData> envDatas;
  final Map<String, String> envDataTypes;
  final void Function(EnvData) onAdd;
  final void Function(int) onDelete;

  const EnvDataGrid({
    super.key,
    required this.envDatas,
    required this.envDataTypes,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: envDatas.length + (envDatas.length < 10 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == envDatas.length && envDatas.length < 10) {
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("Chọn loại cây"),
                  children: envDataTypes.entries.map((entry) {
                    return SimpleDialogOption(
                      onPressed: () {
                        onAdd(EnvData(name: entry.key, imagePath: entry.value));
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
                ),
              );
            },
            child: Card(
              color: Colors.green[50],
              child: const Center(child: Text("➕ Thêm cây")),
            ),
          );
        } else {
          final envData = envDatas[index];
          return Card(
            elevation: 2,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(envData.imagePath, width: 60, height: 60),
                      const SizedBox(height: 8),
                      Text(envData.name),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDelete(index),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
