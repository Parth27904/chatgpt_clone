// lib/models/conversation.dart
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'message.dart';

const _uuid = Uuid();

class Conversation extends Equatable {
  final String id;
  final String deviceId; // <--- NEW FIELD: Device identifier
  final List<Message> messages;
  final DateTime createdAt;
  final String modelUsed;

  const Conversation({
    required this.id,
    required this.deviceId, // <--- NEW
    required this.messages,
    required this.createdAt,
    required this.modelUsed,
  });

  // Updated factory constructor to include deviceId
  factory Conversation.create({required String model, required String deviceId}) { // <--- MODIFIED
    return Conversation(
      id: _uuid.v4(),
      deviceId: deviceId, // <--- SET DEVICE ID
      messages: const [],
      createdAt: DateTime.now(),
      modelUsed: model,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] as String,
      deviceId: json['deviceId'] as String, // <--- NEW
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      modelUsed: json['modelUsed'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'deviceId': deviceId, // <--- NEW
      'messages': messages.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'modelUsed': modelUsed,
    };
  }

  Conversation addMessage(Message message) {
    return copyWith(messages: [...messages, message]);
  }

  Conversation updateMessage(String messageId, String newContent) {
    return copyWith(
      messages: messages.map((msg) {
        if (msg.id == messageId) {
          return Message(
            id: msg.id,
            content: newContent,
            sender: msg.sender,
            timestamp: msg.timestamp,
            imageUrl: msg.imageUrl,
          );
        }
        return msg;
      }).toList(),
    );
  }

  Conversation copyWith({
    String? id,
    String? deviceId, // <--- NEW
    List<Message>? messages,
    DateTime? createdAt,
    String? modelUsed,
  }) {
    return Conversation(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId, // <--- Handle deviceId
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      modelUsed: modelUsed ?? this.modelUsed,
    );
  }

  @override
  List<Object?> get props => [id, deviceId, messages, createdAt, modelUsed]; // <--- Add to props
}