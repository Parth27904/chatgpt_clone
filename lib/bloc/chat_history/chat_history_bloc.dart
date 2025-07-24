// lib/bloc/chat_history/chat_history_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chatgpt_clone/models/conversation.dart';
import 'package:chatgpt_clone/repositories/chat_repository.dart';

part 'chat_history_event.dart';
part 'chat_history_state.dart';

class ChatHistoryBloc extends Bloc<ChatHistoryEvent, ChatHistoryState> {
  final ChatRepository _chatRepository;
  final String _deviceId; // <--- NEW: Store deviceId

  ChatHistoryBloc({required ChatRepository chatRepository, required String deviceId}) // <--- NEW: Accept deviceId
      : _chatRepository = chatRepository,
        _deviceId = deviceId, // <--- NEW
        super(const ChatHistoryState()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<AddConversationToHistory>(_onAddConversationToHistory);
    on<UpdateConversationInHistory>(_onUpdateConversationInHistory);
    on<DeleteConversationFromHistory>(_onDeleteConversationFromHistory);
  }

  Future<void> _onLoadChatHistory(
      LoadChatHistory event,
      Emitter<ChatHistoryState> emit,
      ) async {
    emit(state.copyWith(status: ChatHistoryStatus.loading));
    try {
      // ChatRepository now automatically filters by its injected deviceId
      final conversations = await _chatRepository.loadAllConversations();
      emit(state.copyWith(
        status: ChatHistoryStatus.loaded,
        conversations: conversations,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatHistoryStatus.error,
        error: 'Failed to load chat history: $e',
      ));
    }
  }

  Future<void> _onAddConversationToHistory(
      AddConversationToHistory event,
      Emitter<ChatHistoryState> emit,
      ) async {
    try {
      // ChatRepository ensures the deviceId is added before saving
      await _chatRepository.saveConversation(event.conversation);
      add(const LoadChatHistory()); // Reload history
    } catch (e) {
      emit(state.copyWith(
        status: ChatHistoryStatus.error,
        error: 'Failed to add conversation: $e',
      ));
    }
  }

  Future<void> _onUpdateConversationInHistory(
      UpdateConversationInHistory event,
      Emitter<ChatHistoryState> emit,
      ) async {
    try {
      // ChatRepository ensures the deviceId is handled before saving
      await _chatRepository.saveConversation(event.conversation);
      add(const LoadChatHistory()); // Reload history
    } catch (e) {
      emit(state.copyWith(
        status: ChatHistoryStatus.error,
        error: 'Failed to update conversation: $e',
      ));
    }
  }

  Future<void> _onDeleteConversationFromHistory(
      DeleteConversationFromHistory event,
      Emitter<ChatHistoryState> emit,
      ) async {
    try {
      // ChatRepository ensures the deviceId is handled before deleting
      await _chatRepository.deleteConversation(event.conversationId); // Uses repo's internal deviceId
      add(const LoadChatHistory());
    } catch (e) {
      emit(state.copyWith(
        status: ChatHistoryStatus.error,
        error: 'Failed to delete conversation: $e',
      ));
    }
  }
}