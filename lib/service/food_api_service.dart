import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class FoodApiService {
  // Fetch food suggestions from API (mock or real)
  static Future<List<FoodItem>> fetchFoodSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      // Replace this with your real API URL later
      // For now, using mock data for MVP
      await Future.delayed(const Duration(milliseconds: 300)); // simulate network delay

      final mockData = [
        FoodItem(name: "Rice", calories: 360, carbs: 80, protein: 7, fat: 0.6),
        FoodItem(name: "Toor Dal", calories: 343, carbs: 63, protein: 22, fat: 2),
        FoodItem(name: "Moong Dal", calories: 347, carbs: 63, protein: 24, fat: 1),
        FoodItem(name: "Banana", calories: 89, carbs: 23, protein: 1.1, fat: 0.3),
        FoodItem(name: "Paneer", calories: 200, carbs: 0.5, protein: 28, fat: 11),
      ];

      return mockData
          .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      /*
      // Uncomment this section for real API later
      final url = Uri.parse("https://api.example.com/search?query=$query");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['foods'] as List).map((f) {
          return FoodItem(
            name: f['name'],
            calories: f['calories'].toDouble(),
            carbs: f['carbs'].toDouble(),
            protein: f['protein'].toDouble(),
            fat: f['fat'].toDouble(),
          );
        }).toList();
      } else {
        return [];
      }
      */

    } catch (e) {
      print("Error fetching food suggestions: $e");
      return [];
    }
  }
}
