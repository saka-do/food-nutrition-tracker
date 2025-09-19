class FoodItem {
  int? id;
  late String name;
  late double calories;
  late double carbs;
  late double protein;
  late double fat;

  FoodItem({
    this.id,
    required this.calories,
    required this.name,
    required this.carbs,
    required this.protein,
    required this.fat
  });


  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'name': name,
      "calories": calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat
    };
  }


  factory FoodItem.fromMap(Map<String, dynamic> map){
    return FoodItem(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      carbs: map['carbs'],
      protein: map['protein'],
      fat: map['fat']
    );
  }


}