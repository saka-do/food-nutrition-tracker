import 'package:flutter/material.dart';
import '../db/food_database.dart';
import '../models/recipe.dart';
import '../models/food_item.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({Key? key}) : super(key: key);

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<Recipe> recipes = [];
  Map<int, Map<String, double>> recipeMacros = {};

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final data = await FoodDatabase.instance.getAllRecipes();
    final allFoods = await FoodDatabase.instance.readAllFoods();
    Map<int, Map<String, double>> macroMap = {};

    for (final recipe in data) {
      final items = await FoodDatabase.instance.getRecipeItemsByRecipeId(recipe.id!);
      double totalCals = 0, totalCarbs = 0, totalProtein = 0, totalFat = 0;

      for (final item in items) {
        final food = allFoods.firstWhere(
          (f) => f.id == item.foodId,
          orElse: () => allFoods.first,
        );
        final ratio = item.intake / 100.0;
        totalCals += food.calories * ratio;
        totalCarbs += food.carbs * ratio;
        totalProtein += food.protein * ratio;
        totalFat += food.fat * ratio;
      }

      macroMap[recipe.id!] = {
        'calories': totalCals,
        'carbs': totalCarbs,
        'protein': totalProtein,
        'fat': totalFat,
      };
    }

    setState(() {
      recipes = data;
      recipeMacros = macroMap;
    });
  }

  void _showRecipeDialog({Recipe? recipe}) async {
    await showDialog(
      context: context,
      builder: (context) => RecipeDialog(recipe: recipe, onSaved: _loadRecipes),
    );
  }

  void _deleteRecipe(int id) async {
    await FoodDatabase.instance.deleteRecipe(id);
    _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: recipes.isEmpty
          ? const Center(child: Text("No recipes yet. Tap + to add one."))
          : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                final macros = recipeMacros[recipe.id] ??
                    {'calories': 0, 'carbs': 0, 'protein': 0, 'fat': 0};

                return ListTile(
                  title: Text(recipe.name),
                  subtitle: Text(
                    'Calories: ${macros['calories']!.toStringAsFixed(1)} | '
                    'Carbs: ${macros['carbs']!.toStringAsFixed(1)} | '
                    'Protein: ${macros['protein']!.toStringAsFixed(1)} | '
                    'Fat: ${macros['fat']!.toStringAsFixed(1)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showRecipeDialog(recipe: recipe),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteRecipe(recipe.id!),
                      ),
                    ],
                  ),
                  onTap: () => _showRecipeDialog(recipe: recipe),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecipeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RecipeDialog extends StatefulWidget {
  final Recipe? recipe;
  final VoidCallback onSaved;
  const RecipeDialog({Key? key, this.recipe, required this.onSaved})
      : super(key: key);

  @override
  State<RecipeDialog> createState() => _RecipeDialogState();
}

class _RecipeDialogState extends State<RecipeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  List<_RecipeItemInput> items = [];
  List<FoodItem> allFoods = [];
  int? _timeMinutes;

  @override
  void initState() {
    super.initState();
    _timeMinutes = widget.recipe?.time;
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _loadFoods();
    if (widget.recipe != null) {
      _loadRecipeItems(widget.recipe!.id!);
    } else {
      items.add(_RecipeItemInput());
    }
  }

  Future<void> _loadFoods() async {
    allFoods = await FoodDatabase.instance.readAllFoods();
    setState(() {});
  }

  Future<void> _loadRecipeItems(int recipeId) async {
    final recipeItems =
        await FoodDatabase.instance.getRecipeItemsByRecipeId(recipeId);
    setState(() {
      items = recipeItems
          .map((e) => _RecipeItemInput(foodId: e.foodId, intake: e.intake))
          .toList();
      if (items.isEmpty) items.add(_RecipeItemInput());
    });
  }

  void _addItem() {
    setState(() {
      items.add(_RecipeItemInput());
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    int? timeToSave = _timeMinutes;
    if (timeToSave == null) {
      final nowTime = TimeOfDay.now();
      timeToSave = nowTime.hour * 60 + nowTime.minute;
    }
    final recipe = Recipe(
      id: widget.recipe?.id,
      name: _nameController.text.trim(),
      createdAt: widget.recipe?.createdAt ?? now,
      time: timeToSave,
    );
    int recipeId;
    if (widget.recipe == null) {
      recipeId = await FoodDatabase.instance.createRecipe(recipe);
    } else {
      await FoodDatabase.instance.updateRecipe(recipe);
      recipeId = recipe.id!;
      final oldItems =
          await FoodDatabase.instance.getRecipeItemsByRecipeId(recipeId);
      for (final item in oldItems) {
        await FoodDatabase.instance.deleteRecipeItem(item.id!);
      }
    }
    for (final item in items) {
      if (item.foodId != null && item.intake != null && item.intake! > 0) {
        await FoodDatabase.instance.addRecipeItem(
          RecipeItem(
            recipeId: recipeId,
            foodId: item.foodId!,
            intake: item.intake!,
          ),
        );
      }
    }
    widget.onSaved();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.recipe == null ? 'Add Recipe' : 'Edit Recipe'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Recipe Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _timeMinutes != null
                        ? TimeOfDay(
                            hour: _timeMinutes! ~/ 60,
                            minute: _timeMinutes! % 60,
                          )
                        : TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _timeMinutes = picked.hour * 60 + picked.minute;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Time (hh:mm, optional)',
                    ),
                    controller: TextEditingController(
                      text: _timeMinutes != null
                          ? '${(_timeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(_timeMinutes! % 60).toString().padLeft(2, '0')}'
                          : '',
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Items:'),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: item.foodId,
                          items: allFoods
                              .map(
                                (food) => DropdownMenuItem(
                                  value: food.id,
                                  child: Text(food.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => item.foodId = v),
                          decoration:
                              const InputDecoration(labelText: 'Food'),
                          validator: (v) =>
                              v == null ? 'Select food' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: item.intake?.toString(),
                          decoration: const InputDecoration(labelText: 'g'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) =>
                              item.intake = double.tryParse(v),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0) return 'g?';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Item"),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveRecipe, child: const Text('Save')),
      ],
    );
  }
}

class _RecipeItemInput {
  int? foodId;
  double? intake;
  _RecipeItemInput({this.foodId, this.intake});
}
