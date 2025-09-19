class FoodLog {
  int? id;
  String date;   // stored as yyyy-MM-dd
  String food;
  double intake;
  double calories;
  double carbs;
  double protein;
  double fat;

  FoodLog({
    this.id,
    required this.date,
    required this.food,
    required this.intake,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'food': food,
      'intake': intake,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
    };
  }

  factory FoodLog.fromMap(Map<String, dynamic> map) {
    return FoodLog(
      id: map['id'],
      date: map['date'],
      food: map['food'],
      intake: map['intake'],
      calories: map['calories'],
      carbs: map['carbs'],
      protein: map['protein'],
      fat: map['fat'],
    );
  }
}
