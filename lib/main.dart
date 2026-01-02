import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/pages/chat_screen.dart';
import 'presentation/bloc/chat_bloc.dart';
import 'core/services/inference_orchestrator.dart';
// import 'core/services/extraction_service.dart';
import 'data/repositories/chat_repository_impl.dart';
// import 'data/repositories/model_repository_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalChatApp());
}

class LocalChatApp extends StatelessWidget {
  const LocalChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dependency Injection Root
    // Ideally use GetIt, but simplified here.
    // final extractionService = ExtractionService();
    // final modelRepository = ModelRepositoryImpl(extractionService); // Unused for now, but ready
    final orchestrator = InferenceOrchestrator();
    final chatRepository = ChatRepositoryImpl(orchestrator);

    return MaterialApp(
      title: 'Local LLM Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: RepositoryProvider.value(
        value: chatRepository,
        child: BlocProvider(
          create: (context) => ChatBloc(chatRepository),
          child: const ChatScreen(),
        ),
      ),
    );
  }
}
