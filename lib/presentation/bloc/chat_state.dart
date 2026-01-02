import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message.dart';

enum ChatStatus { initial, loadingModel, ready, streaming, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? errorMessage;
  final String? activeModel;
  final bool isHardwareAccelerated;
  final String? engineType;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
    this.activeModel,
    this.isHardwareAccelerated = false,
    this.engineType,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? errorMessage,
    String? activeModel,
    bool? isHardwareAccelerated,
    String? engineType,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
      activeModel: activeModel ?? this.activeModel,
      isHardwareAccelerated:
          isHardwareAccelerated ?? this.isHardwareAccelerated,
      engineType: engineType ?? this.engineType,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    errorMessage,
    activeModel,
    isHardwareAccelerated,
    engineType,
  ];
}
