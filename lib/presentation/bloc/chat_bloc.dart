import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<String>? _messageSubscription;

  ChatBloc(this._chatRepository) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<LoadModelRequested>(_onLoadModel);
    on<ChatMessageSent>(_onMessageSent);
  }

  void _onStarted(ChatStarted event, Emitter<ChatState> emit) {
    emit(state.copyWith(status: ChatStatus.initial));
  }

  Future<void> _onLoadModel(
    LoadModelRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loadingModel));
    try {
      await _chatRepository.initializeSession(event.modelPath);
      emit(
        state.copyWith(
          status: ChatStatus.ready,
          activeModel: event.modelPath,
          messages: _chatRepository.getHistory(), // Load persistence if any
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage: 'Failed to load model: $e',
        ),
      );
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistic update
    // ChatRepository updates history internally, so we should rely on that or update local state.
    // However, repository doesn't emit history updates except via sendMessage stream.
    // Ideally we want to show User message immediately.

    // Using internal history reference or just simpler:
    // We assume repo.sendMessage adds user message to Repo history.
    // We should refresh messages list from Repo.

    // BUT sendMessage returns a stream of chunks.

    // Emit streaming state with optimistic user message (already in repo history?)
    // Verify repo history has user message
    // Actually, sendMessage adds it.
    // We should wait for first chunk or just emit streaming immediately.

    emit(
      state.copyWith(
        status: ChatStatus.streaming,
        messages: _chatRepository.getHistory(),
      ),
    );

    // Cancel previous stream if any?
    await _messageSubscription?.cancel();

    // Listen to stream
    // IMPORTANT: emit is not async-safe within on<Event>.
    // We use emit.forEach for streams strictly, OR manual subscription but careful with emit.
    // "emit.forEach" is best for streams.

    final buffer = StringBuffer(); // Local buffer for this turn

    try {
      final stream = _chatRepository.sendMessage(event.message);

      await emit.forEach<String>(
        stream,
        onData: (chunk) {
          buffer.write(chunk);
          final partialMessage = ChatMessage(
            content: buffer.toString(),
            isUser: false,
            timestamp: DateTime.now(),
          );

          return state.copyWith(
            status: ChatStatus.streaming,
            messages: [..._chatRepository.getHistory(), partialMessage],
          );
        },
        onError: (e, stackTrace) {
          return state.copyWith(
            status: ChatStatus.failure,
            errorMessage: e.toString(),
          );
        },
      );

      // Stream Done. The Repo will add the full message to history now.
      // We emit the final state with just history (which now includes the full AI message)
      emit(
        state.copyWith(
          status: ChatStatus.ready,
          messages: _chatRepository.getHistory(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
