// lib/services/mongodb_direct_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatgpt_clone/models/conversation.dart';

class MongoDBDirectService {
  late Db _db;
  late DbCollection _conversationsCollection;
  final String _dbName = 'chat_db'; // Your database name

  Future<void> initialize() async {
    final String connectionString = dotenv.env['MONGO_DB_CONNECTION_STRING']!;
    try {
      _db = await Db.create(connectionString);
      await _db.open();
      _conversationsCollection = _db.collection('conversations');
      print("Direct MongoDB connection established successfully!");
    } catch (e) {
      print("Failed to connect directly to MongoDB: $e");
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db.isConnected) {
      await _db.close();
      print("Direct MongoDB connection closed.");
    }
  }

  // Save/Update a conversation
  Future<void> saveConversation(Conversation conversation) async {
    try {
      if (!_db.isConnected) {
        await initialize();
      }
      // conversation.toJson() now includes deviceId implicitly
      await _conversationsCollection.replaceOne(
        where.eq('_id', conversation.id), // Query by _id
        conversation.toJson(),
        upsert: true,
      );
      print('Conversation saved/updated successfully: ${conversation.id}');
    } catch (e) {
      print('Error saving conversation: $e');
      rethrow;
    }
  }

  // Load all conversations from MongoDB for a specific device
  Future<List<Conversation>> loadAllConversations({required String deviceId}) async { // <--- MODIFIED
    try {
      if (!_db.isConnected) {
        await initialize();
      }

      // Filter by deviceId
      final List<Map<String, dynamic>> documents = await _conversationsCollection.find(
          where.eq('deviceId', deviceId) // <--- NEW: Filter by deviceId
      ).toList();
      print('Loaded ${documents.length} conversations for device: $deviceId');
      return documents.map((doc) => Conversation.fromJson(doc)).toList();
    } catch (e) {
      print('Error loading conversations for device $deviceId: $e');
      return [];
    }
  }

  // Get a single conversation by ID for a specific device
  Future<Conversation?> getConversationById(String id, {required String deviceId}) async { // <--- MODIFIED
    try {
      if (!_db.isConnected) {
        await initialize();
      }

      // Filter by _id AND deviceId
      final Map<String, dynamic>? document = await _conversationsCollection.findOne(
          where.eq('_id', id).and(where.eq('deviceId', deviceId)) // <--- NEW: Filter by deviceId
      );
      if (document != null) {
        print('Found conversation $id for device $deviceId');
        return Conversation.fromJson(document);
      }
      print('Conversation $id not found for device $deviceId');
      return null;
    } catch (e) {
      print('Error getting conversation by ID $id for device $deviceId: $e');
      rethrow;
    }
  }

  // Delete a conversation by ID for a specific device
  Future<void> deleteConversation(String conversationId, {required String deviceId}) async { // <--- MODIFIED
    try {
      if (!_db.isConnected) {
        await initialize();
      }

      // Delete by _id AND deviceId
      await _conversationsCollection.deleteOne(
          where.eq('_id', conversationId).and(where.eq('deviceId', deviceId)) // <--- NEW: Filter by deviceId
      );
      print('Conversation deleted successfully: $conversationId for device: $deviceId');
    } catch (e) {
      print('Error deleting conversation $conversationId for device $deviceId: $e');
      rethrow;
    }
  }
}