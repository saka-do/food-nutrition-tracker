import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/food_database.dart';
import '../models/food_item.dart';
import '../models/food_log.dart';
import '../models/recipe.dart';
import '../models/recipe_item_input.dart';

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
    final allRecipes = await FoodDatabase.instance.getAllRecipes();
    FoodItem? selectedFood;
    Recipe? selectedRecipe;
    final intakeController = TextEditingController();
    String searchQuery = "";
    List<FoodItem> filteredFoods = allFoods;
    bool isRecipe = false;
    List<RecipeItemInput> customRecipeItems = [];

    if (editLog != null) {
      selectedFood = allFoods.firstWhere(
        (f) => f.name == editLog.food,
        orElse: () => allFoods.first,
      );
      intakeController.text = editLog.intake.toString();
    }

    await showDialog(
      context: context,
      builder: (BuildContext contextDialog) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(editLog == null ? "Add Log" : "Edit Log"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Food'),
                        value: false,
                        groupValue: isRecipe,
                        onChanged: (v) => setStateDialog(() => isRecipe = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Recipe'),
                        value: true,
                        groupValue: isRecipe,
                        onChanged: (v) => setStateDialog(() => isRecipe = v!),
                      ),
                    ),
                  ],
                ),
                if (!isRecipe) ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Search Food",
                    ),
                    onChanged: (value) {
                      searchQuery = value.toLowerCase();
                      setStateDialog(() {
                        filteredFoods = allFoods
                            .where((f) =>
                                f.name.toLowerCase().contains(searchQuery))
                            .toList();
                      });
                    },
                  ),
                  DropdownButton<FoodItem>(
                    hint: const Text("Select Food"),
                    value: selectedFood,
                    items: filteredFoods.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f.name));
                    }).toList(),
                    onChanged: (f) {
                      setStateDialog(() => selectedFood = f);
                    },
                  ),
                  TextField(
                    controller: intakeController,
                    decoration:
                        const InputDecoration(labelText: "Intake (grams)"),
                    keyboardType: TextInputType.number,
                  ),
                ] else ...[
                  DropdownButton<Recipe>(
                    hint: const Text("Select Recipe"),
                    value: selectedRecipe,
                    items: allRecipes.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.name));
                    }).toList(),
                    onChanged: (r) async {
                      selectedRecipe = r;
                      if (selectedRecipe != null) {
                        final items = await FoodDatabase.instance
                            .getRecipeItemsByRecipeId(selectedRecipe!.id!);
                        setStateDialog(() {
                          customRecipeItems = items
                              .map((e) => RecipeItemInput(
                                  foodId: e.foodId, intake: e.intake))
                              .toList();
                          if (customRecipeItems.isEmpty) {
                            customRecipeItems.add(RecipeItemInput());
                          }
                        });
                      }
                    },
                  ),
                  if (selectedRecipe != null)
                    Column(
                      children: [
                        ...customRecipeItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<int>(
                                    value: item.foodId,
                                    items: allFoods
                                        .map((food) => DropdownMenuItem(
                                              value: food.id,
                                              child: Text(
                                                food.name,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setStateDialog(() => item.foodId = v),
                                    decoration: const InputDecoration(
                                        labelText: 'Food'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: item.intake?.toString(),
                                    decoration: const InputDecoration(
                                        labelText: 'g'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => item.intake =
                                        double.tryParse(v),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (customRecipeItems.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      setStateDialog(() =>
                                          customRecipeItems.removeAt(idx));
                                    },
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        // single + button below all rows
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Add Item"),
                            onPressed: () {
                              setStateDialog(() =>
                                  customRecipeItems.add(RecipeItemInput()));
                            },
                          ),
                        )
                      ],
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialog),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!isRecipe) {
                  if (selectedFood != null &&
                      intakeController.text.isNotEmpty) {
                    final intake = double.parse(intakeController.text);
                    final log = FoodLog(
                      id: editLog?.id,
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
                    Navigator.pop(contextDialog);
                  }
                } else {
                  if (selectedRecipe != null &&
                      customRecipeItems.isNotEmpty) {
                    double totalCals = 0,
                        totalCarbs = 0,
                        totalProtein = 0,
                        totalFat = 0,
                        totalIntake = 0;
                    for (final item in customRecipeItems) {
                      if (item.foodId != null &&
                          item.intake != null &&
                          item.intake! > 0) {
                        final food = allFoods.firstWhere(
                          (f) => f.id == item.foodId,
                          orElse: () => allFoods.first,
                        );
                        final ratio = item.intake! / 100.0;
                        totalCals += food.calories * ratio;
                        totalCarbs += food.carbs * ratio;
                        totalProtein += food.protein * ratio;
                        totalFat += food.fat * ratio;
                        totalIntake += item.intake!;
                      }
                    }
                    final log = FoodLog(
                      id: editLog?.id,
                      date: DateFormat("yyyy-MM-dd").format(selectedDate),
                      food: selectedRecipe!.name,
                      intake: totalIntake,
                      calories: totalCals,
                      carbs: totalCarbs,
                      protein: totalProtein,
                      fat: totalFat,
                    );
                    if (editLog == null) {
                      await FoodDatabase.instance.createLog(log);
                    } else {
                      await FoodDatabase.instance.updateLog(log);
                    }
                    _loadLogs();
                    Navigator.pop(contextDialog);
                  }
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
        title: GestureDetector(
          onTap: () async {
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
          child: Text(dateLabel),
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Totals for $dateLabel",
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
                          (log.intake > 0
                                  ? "Intake: ${log.intake} g\n"
                                  : "") +
                              "C:${log.calories.toStringAsFixed(1)} | "
                              "Carb:${log.carbs.toStringAsFixed(1)} | "
                              "P:${log.protein.toStringAsFixed(1)} | "
                              "F:${log.fat.toStringAsFixed(1)}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            await FoodDatabase.instance.deleteLog(log.id!);
                            _loadLogs();
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
        onPressed: _addLogDialog,
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
