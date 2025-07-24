part of 'model_selection_bloc.dart';

abstract class ModelSelectionEvent extends Equatable {
  const ModelSelectionEvent();

  @override
  List<Object> get props => [];
}

class LoadSelectedModel extends ModelSelectionEvent {
  const LoadSelectedModel();
}

class SelectModel extends ModelSelectionEvent {
  final String model;
  const SelectModel(this.model);

  @override
  List<Object> get props => [model];
}