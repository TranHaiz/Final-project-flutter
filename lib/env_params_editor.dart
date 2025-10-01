import 'package:flutter/material.dart';

import 'data_types.dart';

class EnvParamsEditor extends StatelessWidget {
  final Garden garden;
  final List<String> envParamsTypes;
  final void Function(Map<String, double>) onSave;

  const EnvParamsEditor({
    super.key,
    required this.garden,
    required this.envParamsTypes,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final controllers = {
      for (var key in envParamsTypes)
        key: TextEditingController(text: garden.envParams[key]?.toString() ?? "")
    };

    return AlertDialog(
      title: const Text("Chỉnh thông số môi trường"),
      content: SingleChildScrollView(
        child: Column(
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
            final newParams = <String, double>{};
            for (var param in envParamsTypes) {
              final val = double.tryParse(controllers[param]!.text);
              if (val != null) newParams[param] = val;
            }
            onSave(newParams);
            Navigator.pop(context);
          },
          child: const Text("Lưu"),
        )
      ],
    );
  }
}