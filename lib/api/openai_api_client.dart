// lib/api/openai_api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chatgpt_clone/models/message.dart';

class OpenAIApiClient {
  final String apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIApiClient({required this.apiKey});

  Future<String> getChatCompletion({
    required List<Message> messages, // List of our custom Message objects
    required String model,
  }) async {
    try {
      // Convert our custom Message objects into OpenAI API's expected format.
      // This now supports multimodal content for user messages (text + image).
      final List<Map<String, dynamic>> formattedMessages = [];

      for (var msg in messages) {
        if (msg.sender == MessageSender.user) {
          // A user message can contain an array of content parts (text and/or image)
          final List<Map<String, dynamic>> contentParts = [];

          if (msg.content.isNotEmpty) {
            contentParts.add({'type': 'text', 'text': msg.content});
          }
          if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
            // Add image_url part if an image URL is present
            contentParts.add({
              'type': 'image_url',
              'image_url': {
                'url': msg.imageUrl!,
                // 'detail': 'low', // Optional: 'low', 'high', or 'auto'. 'high' is more expensive.
              }
            });
          }

          // Ensure contentParts is not empty, otherwise, OpenAI API might error.
          // If only image, and no text, contentParts will only have image.
          // If only text, contentParts will only have text.
          // If both, both are included.
          if (contentParts.isNotEmpty) {
            formattedMessages.add({'role': 'user', 'content': contentParts});
          } else {
            // Handle case where user message has neither text nor image (should ideally be prevented earlier)
            // For now, if no content, skip or add a placeholder to prevent API error
            print('OpenAIApiClient: Warning: User message with ID ${msg.id} has no content or image. Skipping for API call.');
          }
        } else {
          // Assistant/Bot messages are typically just text content
          formattedMessages.add({'role': 'assistant', 'content': msg.content});
        }
      }

      print('OpenAIApiClient: Sending formatted messages to OpenAI for Vision: $formattedMessages');
      print('OpenAIApiClient: Using model: $model');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model, // Must be a vision-capable model (e.g., "gpt-4o", "gpt-4-turbo")
          'messages': formattedMessages,
          'temperature': 0.7, // Creativity level
          'max_tokens': 500, // Increased max_tokens for potentially longer image analysis responses
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? botContent = data['choices'][0]['message']['content'] as String?;
        if (botContent != null && botContent.isNotEmpty) {
          return botContent;
        } else {
          print('OpenAI API: Received empty content from bot.');
          return "I didn't receive a response from the AI.";
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('OpenAI API Error: ${response.statusCode} - ${errorData}');
        throw Exception(
            'Failed to get chat completion from OpenAI: ${errorData['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error calling OpenAI API: $e');
      throw Exception('Failed to connect to OpenAI API: $e');
    }
  }
}