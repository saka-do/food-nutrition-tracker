import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/food_database.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';
import 'package:collection/collection.dart';


class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  List<FoodLog> todayLogs = [];
  DateTime selectedDate = DateTime.now();
  double totalCalories = 0;
  double totalCarbs = 0;
  double totalProtein = 0;
  double totalFat = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final dateStr = DateFormat("yyyy-MM-dd").format(selectedDate);
    final logs = await FoodDatabase.instance.readLogsByDate(dateStr);

    double cals = 0, carbs = 0, protein = 0, fat = 0;
    for (var log in logs) {
      cals += log.calories;
      carbs += log.carbs;
      protein += log.protein;
      fat += log.fat;
    }

    setState(() {
      todayLogs = logs;
      totalCalories = cals;
      totalCarbs = carbs;
      totalProtein = protein;
      totalFat = fat;
    });
  }

  Future<void> _addLogDialog({FoodLog? editLog}) async {
    final allFoods = await FoodDatabase.instance.readAllFoods();
    FoodItem? selectedFood;
    final intakeController = TextEditingController();

    String searchQuery = "";
    List<FoodItem> filteredFoods = allFoods; // initially all foods

    // Pre-fill if editing
    if (editLog != null) {
      selectedFood = allFoods.firstWhereOrNull((f) => f.name == editLog.food);
      intakeController.text = editLog.intake.toString();
    }

    await showDialog(
      context: context,
      builder: (BuildContext contextDialog) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(editLog == null ? "Add Food Log" : "Edit Food Log"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Field
              TextField(
                decoration: const InputDecoration(
                  labelText: "Search Food",
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) {
                  setStateDialog(() {
                    searchQuery = val.toLowerCase();
                    filteredFoods = allFoods
                        .where(
                          (f) => f.name.toLowerCase().contains(searchQuery),
                        )
                        .toList();

                    // Reset selectedFood if it no longer exists in filteredFoods
                    if (selectedFood != null &&
                        !filteredFoods.contains(selectedFood)) {
                      selectedFood = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 10),

              // Food Dropdown
              DropdownButton<FoodItem>(
                hint: const Text("Select Food"),
                value: selectedFood,
                isExpanded: true,
                items: filteredFoods.map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.name));
                }).toList(),
                onChanged: (f) {
                  setStateDialog(() => selectedFood = f);
                },
              ),

              // Intake field
              TextField(
                controller: intakeController,
                decoration: const InputDecoration(labelText: "Intake (grams)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialog),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedFood != null && intakeController.text.isNotEmpty) {
                  final intake = double.parse(intakeController.text);

                  final log = FoodLog(
                    id: editLog?.id, // for updates
                    date: DateFormat("yyyy-MM-dd").format(selectedDate),
                    food: selectedFood!.name,
                    intake: intake,
                    calories: selectedFood!.calories * intake / 100,
                    carbs: selectedFood!.carbs * intake / 100,
                    protein: selectedFood!.protein * intake / 100,
                    fat: selectedFood!.fat * intake / 100,
                  );

                  if (editLog == null) {
                    await FoodDatabase.instance.createLog(log);
                  } else {
                    await FoodDatabase.instance.updateLog(log);
                  }

                  _loadLogs();
                  Navigator.pop(contextDialog); // close dialog
                }
              },
              child: Text(editLog == null ? "Add" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat("MMM dd, yyyy").format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text("Food Log - $dateLabel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
                _loadLogs();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Daily Totals Card
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Today's Totals",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBox("Calories", totalCalories),
                      _statBox("Carbs", totalCarbs),
                      _statBox("Protein", totalProtein),
                      _statBox("Fat", totalFat),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Logs list
          Expanded(
            child: todayLogs.isEmpty
                ? const Center(child: Text("No logs for this day"))
                : ListView.builder(
                    itemCount: todayLogs.length,
                    itemBuilder: (context, index) {
                      final log = todayLogs[index];
                      return ListTile(
                        title: Text(log.food),
                        subtitle: Text(
                          "Intake: ${log.intake} g\n"
                          "C:${log.calories.toStringAsFixed(1)} | "
                          "Carb:${log.carbs.toStringAsFixed(1)} | "
                          "P:${log.protein.toStringAsFixed(1)} | "
                          "F:${log.fat.toStringAsFixed(1)}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            if (log.id != null) {
                              await FoodDatabase.instance.deleteLog(log.id!);
                              _loadLogs();
                            }
                          },
                        ),
                        onTap: () {
                          _addLogDialog(editLog: log);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addLogDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statBox(String label, double value) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}
