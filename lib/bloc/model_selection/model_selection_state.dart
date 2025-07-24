part of 'model_selection_bloc.dart';

class ModelSelectionState extends Equatable {
  final String selectedModel;
  final List<String> availableModels;
  final bool isLoading;
  final String? error;

  const ModelSelectionState({
    required this.selectedModel,
    required this.availableModels,
    this.isLoading = false,
    this.error,
  });

  factory ModelSelectionState.initial({required List<String> availableModels}) {
    return ModelSelectionState(
      selectedModel: ModelRepository.defaultModel, // Use default from repo
      availableModels: availableModels,
    );
  }

  ModelSelectionState copyWith({
    String? selectedModel,
    List<String>? availableModels,
    bool? isLoading,
    String? error,
  }) {
    return ModelSelectionState(
      selectedModel: selectedModel ?? this.selectedModel,
      availableModels: availableModels ?? this.availableModels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [selectedModel, availableModels, isLoading, error];
}