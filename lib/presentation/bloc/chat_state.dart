import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message.dart';

enum ChatStatus { initial, loadingModel, ready, streaming, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? errorMessage;
  final String? activeModel;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
    this.activeModel,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? errorMessage,
    String? activeModel,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage:
          errorMessage, // Clear error if not provided? Or keep? Usually clear on new state.
      activeModel: activeModel ?? this.activeModel,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage, activeModel];
}
