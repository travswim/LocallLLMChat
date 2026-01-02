import '../entities/chat_message.dart';

abstract class ChatRepository {
  Stream<String> sendMessage(String message);
  Future<void> initialize(String modelPath, {bool isAsset = false});
  List<ChatMessage> getHistory();
  bool get isHardwareAccelerated;
  String get activeEngine;
  void clearHistory();
}
