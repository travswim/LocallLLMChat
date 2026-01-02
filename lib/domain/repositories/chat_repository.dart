import '../entities/chat_message.dart';

abstract class ChatRepository {
  Stream<String> sendMessage(String message);
  Future<void> initializeSession(String modelPath);
  List<ChatMessage> getHistory();
  void clearHistory();
}
