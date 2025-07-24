// lib/repositories/chat_repository.dart
import 'dart:io';
import 'package:chatgpt_clone/api/openai_api_client.dart';
import 'package:chatgpt_clone/models/conversation.dart';
import 'package:chatgpt_clone/models/message.dart';
import 'package:chatgpt_clone/services/cloudinary_service.dart';
import 'package:chatgpt_clone/services/mongodb_direct_service.dart'; // Use correct service type
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ChatRepository {
  final OpenAIApiClient openAIClient;
  final CloudinaryService cloudinaryService;
  final MongoDBDirectService mongoService; // Use correct service type
  final String _currentDeviceId; // <--- NEW: To hold the current device ID

  ChatRepository({
    required this.openAIClient,
    required this.cloudinaryService,
    required this.mongoService,
    required String currentDeviceId, // <--- NEW: Inject current device ID
  }) : _currentDeviceId = currentDeviceId; // Initialize currentDeviceId

  // ... (getBotResponse and uploadImage remain the same)

  Future<String> getBotResponse({
    required List<Message> currentChatMessages,
    required String model,
  }) async {
    try {
      final response = await openAIClient.getChatCompletion(
        messages: currentChatMessages,
        model: model,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      return await cloudinaryService.uploadImage(imageFile);
    } catch (e) {
      print('ChatRepository: Error uploading image: $e');
      return null;
    }
  }

  // Load all conversations for the current device
  Future<List<Conversation>> loadAllConversations() async { // <--- NO deviceId param here, uses internal
    try {
      return await mongoService.loadAllConversations(deviceId: _currentDeviceId); // <--- PASS _currentDeviceId
    } catch (e) {
      print('ChatRepository: Error loading conversations from Mongo for device $_currentDeviceId: $e');
      return [];
    }
  }

  // Save conversation for the current device
  Future<void> saveConversation(Conversation conversation) async {
    try {
      // Ensure the conversation object has the correct deviceId before saving
      // This is important for new conversations created in ChatBloc
      final conversationWithDeviceId = conversation.copyWith(deviceId: _currentDeviceId); // <--- ENSURE DEVICEID
      await mongoService.saveConversation(conversationWithDeviceId);
    } catch (e) {
      print('ChatRepository: Error saving conversation to Mongo: $e');
      rethrow;
    }
  }

  // Delete conversation for the current device
  Future<void> deleteConversation(String conversationId) async { // <--- NO deviceId param here
    try {
      await mongoService.deleteConversation(conversationId, deviceId: _currentDeviceId); // <--- PASS _currentDeviceId
    } catch (e) {
      print('ChatRepository: Error deleting conversation from Mongo: $e');
      rethrow;
    }
  }

  // Start new conversation for the current device
  Future<Conversation> startNewConversation({required String model}) async { // <--- NO deviceId param here
    final newConversation = Conversation.create(model: model, deviceId: _currentDeviceId); // <--- PASS _currentDeviceId
    await saveConversation(newConversation);
    return newConversation;
  }

  // Get conversation by ID for the current device
  Future<Conversation?> getConversationById(String id) async { // <--- NO deviceId param here
    try {
      return await mongoService.getConversationById(id, deviceId: _currentDeviceId); // <--- PASS _currentDeviceId
    } catch (e) {
      print('ChatRepository: Error getting conversation by ID from Mongo for device $_currentDeviceId: $e');
      return null;
    }
  }
}