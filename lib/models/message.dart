import 'package:equatable/equatable.dart';

enum MessageSender { user, bot }

class Message extends Equatable {
  final String id; // Unique ID for the message
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final String? imageUrl; // For uploaded images by user

  const Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, content, sender, timestamp, imageUrl];

  // Factory constructor for converting JSON to Message object (for persistence)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: MessageSender.values.firstWhere(
              (e) => e.toString() == 'MessageSender.${json['sender']}'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  // Convert Message object to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}