import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as Math;

import 'package:chatgpt_clone/models/conversation.dart';
import 'package:chatgpt_clone/models/message.dart';
import 'package:chatgpt_clone/repositories/chat_repository.dart';
import 'package:chatgpt_clone/repositories/model_repository.dart';
import 'package:chatgpt_clone/bloc/chat_history/chat_history_bloc.dart';

part 'chat_event.dart';
part 'chat_state.dart';

const _uuid = Uuid();

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final ModelRepository _modelRepository;
  final ChatHistoryBloc _chatHistoryBloc;
  final String _deviceId; // <--- NEW: Store deviceId

  ChatBloc({
    required ChatRepository chatRepository,
    required ModelRepository modelRepository,
    required ChatHistoryBloc chatHistoryBloc,
    required String deviceId, // <--- NEW: Accept deviceId
  })  : _chatRepository = chatRepository,
        _modelRepository = modelRepository,
        _chatHistoryBloc = chatHistoryBloc,
        _deviceId = deviceId, // <--- NEW
        super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<SendMessage>(_onSendMessage);
    on<NewChatStarted>(_onNewChatStarted);
    on<ImagePicked>(_onImagePicked);
    on<ClearImageSelection>(_onClearImageSelection);
  }

  Future<void> _onChatStarted(
      ChatStarted event,
      Emitter<ChatState> emit,
      ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      if (event.conversationId != null) {
        final conversation =
        await _chatRepository.getConversationById(event.conversationId!); // <--- Now uses repo's internal deviceId
        if (conversation != null) {
          emit(state.copyWith(
            status: ChatStatus.loaded,
            currentConversation: conversation,
            error: null,
          ));
        } else {
          // If conversation not found, start a new one with default model for this device
          final selectedModel = await _modelRepository.loadSelectedModel();
          final newConversation = await _chatRepository.startNewConversation(
            model: selectedModel,
          ); // <--- Now uses repo's internal deviceId
          emit(state.copyWith(
            status: ChatStatus.loaded,
            currentConversation: newConversation,
            error: null,
          ));
          _chatHistoryBloc.add(AddConversationToHistory(newConversation));
        }
      } else {
        // If no conversationId, start a new empty conversation for this device
        final selectedModel = await _modelRepository.loadSelectedModel();
        final newConversation = await _chatRepository.startNewConversation(
          model: selectedModel,
        ); // <--- Now uses repo's internal deviceId
        emit(state.copyWith(
          status: ChatStatus.loaded,
          currentConversation: newConversation,
          error: null,
        ));
        _chatHistoryBloc.add(AddConversationToHistory(newConversation));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to load chat: $e',
      ));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event,
      Emitter<ChatState> emit,
      ) async {
    print('ChatBloc: Received SendMessage event.');
    print('ChatBloc: SendMessage event content: "${event.content}"');
    print('ChatBloc: SendMessage event imageFile: ${event.imageFile?.path}');

    if (event.content.trim().isEmpty && event.imageFile == null) {
      print('ChatBloc: Message content is empty and no imageFile in event. Aborting send.');
      return;
    }

    final bool isImageUploadInvolved = event.imageFile != null;

    emit(state.copyWith(
      status: ChatStatus.sendingMessage,
      isImageUploadInProgress: isImageUploadInvolved,
    ));
    print('ChatBloc: AFTER emitting sendingMessage state. Status: ${state.status}, isImageUploadInProgress: ${state.isImageUploadInProgress}');


    try {
      String selectedModel = state.currentConversation?.modelUsed ??
          await _modelRepository.loadSelectedModel();
      print('ChatBloc: Selected model: $selectedModel');

      Conversation current = state.currentConversation ??
          await _chatRepository.startNewConversation(model: selectedModel); // <--- Now uses repo's internal deviceId
      if (state.currentConversation == null) {
        emit(state.copyWith(currentConversation: current));
        _chatHistoryBloc.add(AddConversationToHistory(current));
        print('ChatBloc: Started new conversation: ${current.id}');
      }

      String? uploadedImageUrl;
      if (isImageUploadInvolved) {
        print('ChatBloc: ImageFile present in event. Attempting to upload...');
        uploadedImageUrl = await _chatRepository.uploadImage(File(event.imageFile!.path));

        emit(state.copyWith(
          isImageUploadInProgress: false,
        ));
        print('ChatBloc: Image upload phase finished. isImageUploadInProgress set to false.');

        if (uploadedImageUrl == null) {
          print('ChatBloc: Image upload failed, uploadedImageUrl is null.');
          throw Exception('Image upload failed.');
        } else {
          print('ChatBloc: Image uploaded successfully. URL: $uploadedImageUrl');
        }
      } else {
        print('ChatBloc: No imageFile in event for upload. Proceeding with text-only message.');
      }

      final userMessage = Message(
        id: _uuid.v4(),
        content: event.content,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        imageUrl: uploadedImageUrl,
      );
      current = current.addMessage(userMessage);
      print('ChatBloc: User message added to conversation: "${userMessage.content}", Image URL: ${userMessage.imageUrl}');

      emit(state.copyWith(
        currentConversation: current,
        selectedImage: null, // Clear preview
        status: ChatStatus.sendingMessage, // Remain sending for bot response
      ));
      print('ChatBloc: UI updated, selected image cleared from state. Status remains: ${state.status}');
      await _chatRepository.saveConversation(current);
      print('ChatBloc: Conversation with user message saved to DB.');

      final botMessageId = _uuid.v4();
      final tempBotMessage = Message(
        id: botMessageId,
        content: 'Typing...',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      );
      current = current.addMessage(tempBotMessage);
      emit(state.copyWith(
        currentConversation: current,
        botTypingMessageId: botMessageId,
        status: ChatStatus.sendingMessage,
      ));
      print('ChatBloc: Added "Typing..." placeholder.');

      final botResponse = await _chatRepository.getBotResponse(
        currentChatMessages: current.messages,
        model: selectedModel,
      );
      print('ChatBloc: Received bot response: ${botResponse.substring(0, Math.min(botResponse.length, 50))}...');

      current = current.updateMessage(botMessageId, botResponse);

      emit(state.copyWith(
        status: ChatStatus.loaded, // Final loaded state
        currentConversation: current,
        error: null,
        botTypingMessageId: null,
        isImageUploadInProgress: false,
      ));
      print('ChatBloc: Final conversation state updated and loaded. isImageUploadInProgress ensures false.');
      await _chatRepository.saveConversation(current);
      print('ChatBloc: Conversation with bot response saved to DB.');

      _chatHistoryBloc.add(UpdateConversationInHistory(current));
      print('ChatBloc: Chat history updated.');

    } catch (e) {
      print('ChatBloc: FATAL ERROR during send message process: $e');
      emit(state.copyWith(
        status: ChatStatus.error, // Final error state
        error: 'Failed to send message: ${e.toString()}',
        botTypingMessageId: null,
        isImageUploadInProgress: false,
      ));
    }
  }

  Future<void> _onImagePicked(
      ImagePicked event,
      Emitter<ChatState> emit,
      ) async {
    print('ChatBloc: ImagePicked event received. Path: ${event.imageFile.path}');
    emit(state.copyWith(
      status: ChatStatus.imagePicked,
      selectedImage: event.imageFile,
      error: null,
    ));
    print('ChatBloc: State updated to imagePicked, selectedImage set.');
  }

  Future<void> _onNewChatStarted(
      NewChatStarted event,
      Emitter<ChatState> emit,
      ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final selectedModel = await _modelRepository.loadSelectedModel();
      final newConversation = await _chatRepository.startNewConversation(
        model: selectedModel,
      );
      emit(state.copyWith(
        status: ChatStatus.loaded,
        currentConversation: newConversation,
        error: null,
        selectedImage: null, // Clear any pending image selection
      ));
      _chatHistoryBloc.add(AddConversationToHistory(newConversation));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to start new chat: $e',
      ));
    }
  }

  Future<void> _onClearImageSelection(
      ClearImageSelection event,
      Emitter<ChatState> emit,
      ) async {
    emit(state.copyWith(
      selectedImage: null,
      status: ChatStatus.loaded, // Revert to loaded state
    ));
  }

}