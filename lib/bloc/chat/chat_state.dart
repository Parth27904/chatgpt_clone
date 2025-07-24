// lib/bloc/chat/chat_state.dart
part of 'chat_bloc.dart';

enum ChatStatus {
  initial,
  loading,
  loaded,
  sendingMessage, // Covers both text message sent and bot response
  error,
  imagePicking,
  imagePicked,
}

class ChatState extends Equatable {
  final ChatStatus status;
  final Conversation? currentConversation;
  final String? error;
  final XFile? selectedImage;
  final String? botTypingMessageId;
  final bool isImageUploadInProgress; // <--- NEW FIELD: Added this for conditional text

  const ChatState({
    this.status = ChatStatus.initial,
    this.currentConversation,
    this.error,
    this.selectedImage,
    this.botTypingMessageId,
    this.isImageUploadInProgress = false, // <--- Initialize to false
  });

  ChatState copyWith({
    ChatStatus? status,
    Conversation? currentConversation,
    String? error,
    XFile? selectedImage,
    String? botTypingMessageId,
    bool? isImageUploadInProgress, // <--- Include in copyWith
  }) {
    return ChatState(
      status: status ?? this.status,
      currentConversation: currentConversation ?? this.currentConversation,
      error: error,
      selectedImage: selectedImage, // Keep null if not explicitly set
      botTypingMessageId: botTypingMessageId,
      isImageUploadInProgress: isImageUploadInProgress ?? this.isImageUploadInProgress, // <--- Handle new field
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentConversation,
    error,
    selectedImage,
    botTypingMessageId,
    isImageUploadInProgress, // <--- Add to props list for Equatable
  ];
}