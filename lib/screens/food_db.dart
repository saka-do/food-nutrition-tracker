import 'package:flutter/material.dart';
import '../db/food_database.dart';
import '../models/food_item.dart';
import '../service/food_api_service.dart';

class FoodDBScreen extends StatefulWidget {
  const FoodDBScreen({super.key});

  @override
  State<FoodDBScreen> createState() => _FoodDBScreenState();
}

class _FoodDBScreenState extends State<FoodDBScreen> {
  List<FoodItem> foods = []; // Local DB items
  List<FoodItem> suggestions = []; // API search results
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final dbFoods = await FoodDatabase.instance.readAllFoods();
    setState(() {
      foods = dbFoods;
    });
  }

  // Mock API call for suggestions
  Future<void> _searchFood(String query) async {
    final results = await FoodApiService.fetchFoodSuggestions(query);
    setState(() => suggestions = results);
  }

  Future<void> _addFoodToDb(FoodItem food) async {
    await FoodDatabase.instance.createFood(food);
    searchController.clear();
    setState(() {
      suggestions = [];
    });
    _loadFoods(); // refresh local DB list
  }

  Future<void> _deleteFood(FoodItem food) async {
    if (food.id != null) {
      await FoodDatabase.instance.deleteFood(food.id!);
      _loadFoods();
    }
  }

  Future<void> _editFoodDialog(FoodItem food) async {
    final nameController = TextEditingController(text: food.name);
    final calController = TextEditingController(text: food.calories.toString());
    final carbController = TextEditingController(text: food.carbs.toString());
    final proteinController = TextEditingController(
      text: food.protein.toString(),
    );
    final fatController = TextEditingController(text: food.fat.toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Food Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: calController,
                decoration: InputDecoration(labelText: "Calories"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: carbController,
                decoration: InputDecoration(labelText: "Carbs"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: proteinController,
                decoration: InputDecoration(labelText: "Protein"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatController,
                decoration: InputDecoration(labelText: "Fat"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedFood = FoodItem(
                id: food.id,
                name: nameController.text,
                calories: double.parse(calController.text),
                carbs: double.parse(carbController.text),
                protein: double.parse(proteinController.text),
                fat: double.parse(fatController.text),
              );
              await FoodDatabase.instance.updateFood(updatedFood);
              _loadFoods();
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Food Database")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search Food",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchFood,
            ),

            // Suggestion list
            if (suggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final s = suggestions[index];
                    return ListTile(
                      title: Text(s.name),
                      subtitle: Text(
                        "C:${s.calories} | Carb:${s.carbs} | P:${s.protein} | F:${s.fat}",
                      ),
                      onTap: () => _addFoodToDb(s),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Local DB food list
            Expanded(
              child: foods.isEmpty
                  ? const Center(child: Text("No foods added"))
                  : ListView.builder(
                      itemCount: foods.length,
                      itemBuilder: (context, index) {
                        final food = foods[index];
                        return ListTile(
                          title: Text(food.name),
                          subtitle: Text(
                            "C:${food.calories} | Carb:${food.carbs} | P:${food.protein} | F:${food.fat}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editFoodDialog(food),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  await FoodDatabase.instance.deleteFood(
                                    food.id!,
                                  );
                                  _loadFoods();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
