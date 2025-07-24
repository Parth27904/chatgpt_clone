part of 'chat_history_bloc.dart';

abstract class ChatHistoryEvent extends Equatable {
  const ChatHistoryEvent();

  @override
  List<Object> get props => [];
}

class LoadChatHistory extends ChatHistoryEvent {
  const LoadChatHistory();
}

class AddConversationToHistory extends ChatHistoryEvent {
  final Conversation conversation;
  const AddConversationToHistory(this.conversation);

  @override
  List<Object> get props => [conversation];
}

class UpdateConversationInHistory extends ChatHistoryEvent {
  final Conversation conversation;
  const UpdateConversationInHistory(this.conversation);

  @override
  List<Object> get props => [conversation];
}

class DeleteConversationFromHistory extends ChatHistoryEvent {
  final String conversationId;
  const DeleteConversationFromHistory(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}