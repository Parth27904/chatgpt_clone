import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chatgpt_clone/repositories/model_repository.dart';

part 'model_selection_event.dart';
part 'model_selection_state.dart';

class ModelSelectionBloc extends Bloc<ModelSelectionEvent, ModelSelectionState> {
  final ModelRepository _modelRepository;

  ModelSelectionBloc({required ModelRepository modelRepository})
      : _modelRepository = modelRepository,
        super(ModelSelectionState.initial(
          availableModels: modelRepository.getAvailableModels())) {
    on<LoadSelectedModel>(_onLoadSelectedModel);
    on<SelectModel>(_onSelectModel);
  }

  Future<void> _onLoadSelectedModel(
      LoadSelectedModel event,
      Emitter<ModelSelectionState> emit,
      ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final selectedModel = await _modelRepository.loadSelectedModel();
      emit(state.copyWith(
        selectedModel: selectedModel,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load selected model: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onSelectModel(
      SelectModel event,
      Emitter<ModelSelectionState> emit,
      ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _modelRepository.saveSelectedModel(event.model);
      emit(state.copyWith(
        selectedModel: event.model,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to save selected model: $e',
        isLoading: false,
      ));
    }
  }
}