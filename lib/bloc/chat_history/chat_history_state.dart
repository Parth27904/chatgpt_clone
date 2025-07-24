part of 'chat_history_bloc.dart';

enum ChatHistoryStatus { initial, loading, loaded, error }

class ChatHistoryState extends Equatable {
  final ChatHistoryStatus status;
  final List<Conversation> conversations;
  final String? error;

  const ChatHistoryState({
    this.status = ChatHistoryStatus.initial,
    this.conversations = const [],
    this.error,
  });

  ChatHistoryState copyWith({
    ChatHistoryStatus? status,
    List<Conversation>? conversations,
    String? error,
  }) {
    return ChatHistoryState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, conversations, error];
}