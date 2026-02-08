class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class Recipe {
  final String name;
  final String description;
  final String ingredients;
  final String instructions;
  final int cookingTime;
  final int servings;
  final String category;
  final String tips;

  Recipe({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.servings,
    required this.category,
    required this.tips,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] ?? 'Recipe',
      description: json['description'] ?? '',
      ingredients: json['ingredients'] ?? '',
      instructions: json['instructions'] ?? '',
      cookingTime: json['cookingTime'] ?? 30,
      servings: json['servings'] ?? 4,
      category: json['category'] ?? 'Main',
      tips: json['tips'] ?? '',
    );
  }
}
