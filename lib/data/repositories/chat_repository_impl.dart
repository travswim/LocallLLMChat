import 'dart:async';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../core/services/inference_orchestrator.dart';

class ChatRepositoryImpl implements ChatRepository {
  final InferenceOrchestrator _orchestrator;
  final List<ChatMessage> _history = [];

  ChatRepositoryImpl(this._orchestrator);

  @override
  Future<void> initializeSession(String modelPath) async {
    await _orchestrator.loadModel(modelPath);
  }

  @override
  Stream<String> sendMessage(String message) {
    _history.add(
      ChatMessage(content: message, isUser: true, timestamp: DateTime.now()),
    );

    // Pass prompt to orchestrator.
    // Optimally, we construct a prompt with history here.
    // For simple chat, we might just pass the message or a formatted conversation.
    // Let's do simple pass-through for now, or basic formatting.

    final prompt = _buildPrompt(message);

    final streamController = StreamController<String>();
    final fullResponseBuffer = StringBuffer();

    _orchestrator
        .generateStream(prompt)
        .listen(
          (chunk) {
            fullResponseBuffer.write(chunk);
            streamController.add(chunk);
          },
          onError: (e) {
            streamController.addError(e);
          },
          onDone: () {
            _history.add(
              ChatMessage(
                content: fullResponseBuffer.toString(),
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            streamController.close();
          },
        );

    return streamController.stream;
  }

  String _buildPrompt(String newMessage) {
    // Basic chat format. Adjust for specific model (e.g. Gemma formatting)
    // <start_of_turn>user\n...<end_of_turn><start_of_turn>model\n

    final buffer = StringBuffer();
    // buffer.write("System: You are a helpful assistant.\n"); // If model supports system prompt

    // Naive history context (last 4 messages?)
    final recentHistory = _history.length > 4
        ? _history.sublist(_history.length - 4)
        : _history;

    for (var msg in recentHistory) {
      if (msg.content == newMessage) {
        continue;
      }
      // Actually sendMessage adds it to history BEFORE calling this.
      // So logic ...
    }

    // Re-do history logic:
    // We already added newMessage to _history.
    // We should format ALL (or recent) history including the new message.

    for (var msg in _history) {
      // Use full history or window
      if (msg.isUser) {
        buffer.write("<start_of_turn>user\n${msg.content}<end_of_turn>\n");
      } else {
        buffer.write("<start_of_turn>model\n${msg.content}<end_of_turn>\n");
      }
    }
    buffer.write("<start_of_turn>model\n");
    return buffer.toString();
  }

  @override
  List<ChatMessage> getHistory() => List.unmodifiable(_history);

  @override
  void clearHistory() {
    _history.clear();
  }
}
