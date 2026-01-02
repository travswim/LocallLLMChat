import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../domain/entities/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    context.read<ChatBloc>().add(ChatMessageSent(_textController.text));
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local LLM Chat'),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.activeModel != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        state.isHardwareAccelerated
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: state.isHardwareAccelerated
                            ? Colors.amber
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.engineType?.toUpperCase() ?? 'UNK',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              context.read<ChatBloc>().add(LoadModelRequested(value));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'assets/gemma-2b-it-gpu-int4.bin',
                child: Text('Load Gemma 2B (MediaPipe, Asset)'),
              ),
              const PopupMenuItem(
                value: 'assets/model.tflite',
                child: Text('Load TFLite Model (LiteRT, Asset)'),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.status == ChatStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
          // Scroll on streaming updates
          if (state.status == ChatStatus.streaming ||
              state.status == ChatStatus.ready) {
            // Debounce or just scroll?
            // _scrollToBottom(); // Can be janky if too frequent
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              if (state.status == ChatStatus.loadingModel)
                const LinearProgressIndicator(),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    return _MessageBubble(message: msg);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: state.status == ChatStatus.streaming
                          ? null // Disable while streaming
                          : _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
