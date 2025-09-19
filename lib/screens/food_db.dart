import 'package:flutter/material.dart';
import '../db/food_database.dart';
import '../models/food_item.dart';

class FoodDBScreen extends StatefulWidget {
  const FoodDBScreen({super.key});

  @override
  State<FoodDBScreen> createState() => _FoodDBScreenState();
}

class _FoodDBScreenState extends State<FoodDBScreen> {
  List<FoodItem> foods = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final allFoods = await FoodDatabase.instance.readAllFoods();
    setState(() {
      foods = allFoods;
    });
  }

  Future<void> _addFoodDialog() async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final carbsController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Food Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Food Name")),
              TextField(controller: caloriesController, decoration: const InputDecoration(labelText: "Calories / 100g"), keyboardType: TextInputType.number),
              TextField(controller: carbsController, decoration: const InputDecoration(labelText: "Carbs / 100g"), keyboardType: TextInputType.number),
              TextField(controller: proteinController, decoration: const InputDecoration(labelText: "Protein / 100g"), keyboardType: TextInputType.number),
              TextField(controller: fatController, decoration: const InputDecoration(labelText: "Fat / 100g"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final food = FoodItem(
                name: nameController.text,
                calories: double.parse(caloriesController.text),
                carbs: double.parse(carbsController.text),
                protein: double.parse(proteinController.text),
                fat: double.parse(fatController.text),
              );
              await FoodDatabase.instance.create(food);
              _loadFoods();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = foods
        .where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Food Database"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(labelText: "Search Food"),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                final food = filteredFoods[index];
                return ListTile(
                  title: Text(food.name),
                  subtitle: Text("C:${food.calories} | Carb:${food.carbs} | P:${food.protein} | F:${food.fat}"),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFoodDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
