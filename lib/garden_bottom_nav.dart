import 'package:flutter/material.dart';
import 'data_types.dart';

class GardenBottomNav extends StatelessWidget {
  final List<Garden> gardens;
  final int selectedIndex;
  final int maxGardens;
  final void Function(int) onSelect;
  final VoidCallback onAdd;

  const GardenBottomNav({
    super.key,
    required this.gardens,
    required this.selectedIndex,
    required this.maxGardens,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            for (int i = 0; i < gardens.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grass,
                          size: 20,
                          color: i == selectedIndex
                              ? Colors.green
                              : Colors.grey),
                      Text(
                        gardens[i].name,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              i == selectedIndex ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (gardens.length < maxGardens)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: onAdd,
              ),
          ],
        ),
      ),
    );
  }
}
