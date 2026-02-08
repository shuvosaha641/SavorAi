import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:recipeappflutter/models/chat_message.dart';

class ChatService {

  static const String _backendUrl = 'http://10.0.2.2:8080';

  Future<Recipe> generateRecipe(String ingredients) async {
    try {
      print('Attempting to connect to: $_backendUrl/generate-recipe');
      final resp = await http
          .post(
            Uri.parse('$_backendUrl/generate-recipe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ingredients': ingredients}),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return Recipe.fromJson(data);
      } else {
        throw Exception(
            'Failed to generate recipe: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      print('Error generating recipe: $e');
      rethrow;
    }
  }
}
