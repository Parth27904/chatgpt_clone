// lib/repositories/model_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

class ModelRepository {
  static const String _selectedModelKey = 'selectedModel';
  // Set a vision-capable model as default, or ensure it's in the list
  static const String defaultModel = 'gpt-4o'; // Recommend gpt-4o for vision

  Future<String> loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedModelKey) ?? defaultModel;
  }

  Future<void> saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, model);
  }

  List<String> getAvailableModels() {
    // List models that support vision (and general chat)
    return [
      'gpt-4o', // Best for multimodal
      'gpt-4-turbo', // Also supports vision
      'gpt-4',
      'gpt-3.5-turbo', // Text-only, but good for faster responses
    ];
  }
}