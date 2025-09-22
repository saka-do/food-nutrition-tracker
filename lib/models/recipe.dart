import 'package:flutter/foundation.dart';

class Recipe {
  int? id;
  String name;
  DateTime createdAt;
  int? time; // in minutes, optional

  Recipe({
    this.id,
    required this.name,
    required this.createdAt,
    this.time,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      time: map['time'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'time': time,
    };
  }
}

class RecipeItem {
  int? id;
  int recipeId;
  int foodId;
  double intake; // in grams

  RecipeItem({
    this.id,
    required this.recipeId,
    required this.foodId,
    required this.intake,
  });

  factory RecipeItem.fromMap(Map<String, dynamic> map) {
    return RecipeItem(
      id: map['id'] as int?,
      recipeId: map['recipeId'] as int,
      foodId: map['foodId'] as int,
      intake: (map['intake'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'foodId': foodId,
      'intake': intake,
    };
  }
}
