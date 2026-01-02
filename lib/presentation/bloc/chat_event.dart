import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatStarted extends ChatEvent {}

class LoadModelRequested extends ChatEvent {
  final String modelPath;
  const LoadModelRequested(this.modelPath);

  @override
  List<Object> get props => [modelPath];
}

class ChatMessageSent extends ChatEvent {
  final String message;
  const ChatMessageSent(this.message);

  @override
  List<Object> get props => [message];
}
