import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/food_database.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';

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

  Future<void> _addLogDialog() async {
    final allFoods = await FoodDatabase.instance.readAllFoods();
    FoodItem? selectedFood;
    final intakeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Add Food Log"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<FoodItem>(
                hint: const Text("Select Food"),
                value: selectedFood,
                items: allFoods.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.name),
                  );
                }).toList(),
                onChanged: (f) {
                  setStateDialog(() => selectedFood = f);
                },
              ),
              TextField(
                controller: intakeController,
                decoration: const InputDecoration(labelText: "Intake (grams)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedFood != null &&
                    intakeController.text.isNotEmpty) {
                  final intake = double.parse(intakeController.text);

                  final log = FoodLog(
                    date: DateFormat("yyyy-MM-dd").format(selectedDate),
                    food: selectedFood!.name,
                    intake: intake,
                    calories: selectedFood!.calories * intake / 100,
                    carbs: selectedFood!.carbs * intake / 100,
                    protein: selectedFood!.protein * intake / 100,
                    fat: selectedFood!.fat * intake / 100,
                  );

                  await FoodDatabase.instance.createLog(log);
                  _loadLogs();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
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
        title: Text(dateLabel),
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
          // ✅ Daily Totals card with all macros
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Today's Totals",
                      style: Theme.of(context).textTheme.titleLarge),
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
          // ✅ Logs list
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statBox(String label, double value) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}
