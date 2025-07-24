// lib/bloc/chat/chat_event.dart
part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => []; // Base class expects List<Object>
}

class ChatStarted extends ChatEvent {
  final String? conversationId;
  const ChatStarted({this.conversationId});

  @override
  List<Object> get props => [conversationId ?? ''];
}

class SendMessage extends ChatEvent {
  final String content;
  final XFile? imageFile;
  const SendMessage({required this.content, this.imageFile});

  @override
  // FIX: Ensure all items in props are non-nullable Objects.
  // For nullable XFile, compare its path and provide an empty string if the path is null.
  List<Object> get props => [content, imageFile?.path ?? '']; // <--- THE FIX IS HERE
}

class NewChatStarted extends ChatEvent {
  const NewChatStarted();

  @override
  List<Object> get props => [];
}

class ImagePicked extends ChatEvent {
  final XFile imageFile;
  const ImagePicked({required this.imageFile});

  @override
  List<Object> get props => [imageFile]; // XFile itself is non-nullable here
}

class ClearImageSelection extends ChatEvent {
  const ClearImageSelection();

  @override
  List<Object> get props => [];
}