import 'package:flutter/material.dart';
import 'screens/food_db.dart';
import 'screens/food_log.dart';
import 'screens/weekly_summary.dart';
import 'screens/recipe_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'db/food_database.dart';
import 'models/food_item.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await preloadFoodDB(); // <-- preload JSON into SQLite
  runApp(const NutritionApp());
}

Future<void> preloadFoodDB() async {
  final existingFoods = await FoodDatabase.instance.readAllFoods();
  if (existingFoods.isNotEmpty) return; // already preloaded

  final data = await rootBundle.loadString('lib/assets/foods_data.json');
  final List<dynamic> jsonList = jsonDecode(data);

  for (var item in jsonList) {
    final food = FoodItem(
      name: item['name'],
      calories: item['calories'].toDouble(),
      carbs: item['carbs'].toDouble(),
      protein: item['protein'].toDouble(),
      fat: item['fat'].toDouble(),
    );
    await FoodDatabase.instance.createFood(food);
  }
}


class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Default = Food Log screen

  final List<Widget> _screens = const [
    FoodDBScreen(),
    FoodLogScreen(),
    WeeklySummaryScreen(),
    RecipeScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank),
            label: 'Food DB',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Food Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Weekly',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Recipes',
          ),
        ],
      ),
    );
  }
  
}


