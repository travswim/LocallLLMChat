import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mediapipe_genai/mediapipe_genai.dart';
import 'inference_provider.dart';

class MediaPipeEngine implements InferenceProvider {
  LlmInferenceEngine? _engine;
  bool _isHardwareAccelerated = false;

  @override
  String get engineKey => 'mediapipe';

  @override
  bool get isHardwareAccelerated => _isHardwareAccelerated;

  @override
  bool supportsExtension(String extension) {
    return extension == '.bin' ||
        extension ==
            '.tflite'; // GenAI usually uses specialized formats or .tflite
  }

  @override
  Future<void> loadModel(String modelPath, {bool isAsset = false}) async {
    if (_engine != null) {
      _engine!.dispose();
    }

    // MediaPipe GenAI requires a cache directory for some backends
    final supportDir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${supportDir.path}/llm_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // Default options config
    const maxTokens = 512;
    const temperature = 0.7;
    const topK = 40;
    const randomSeed = 0; // Fixed seed for reproducibility? Or random.

    // Try GPU First
    try {
      debugPrint('MediaPipeEngine: Attempting to load with GPU delegate...');
      final options = LlmInferenceOptions.gpu(
        modelPath: modelPath,
        sequenceBatchSize: 1, // Default for mobile
        maxTokens: maxTokens,
        temperature: temperature,
        topK: topK,
        randomSeed: randomSeed,
      );

      _engine = LlmInferenceEngine(options);
      _isHardwareAccelerated = true;
      debugPrint('MediaPipeEngine: Loaded with GPU.');
    } catch (e) {
      debugPrint(
        'MediaPipeEngine: GPU initialization failed: $e. Falling back to CPU.',
      );

      // Fallback to CPU
      try {
        final options = LlmInferenceOptions.cpu(
          modelPath: modelPath,
          cacheDir: cacheDir.path,
          maxTokens: maxTokens,
          temperature: temperature,
          topK: topK,
          randomSeed: randomSeed,
        );

        _engine = LlmInferenceEngine(options);
        _isHardwareAccelerated = false;
        debugPrint('MediaPipeEngine: Loaded with CPU.');
      } catch (e2) {
        throw Exception(
          'MediaPipeEngine: Failed to initialize with CPU fallback. Error: $e2',
        );
      }
    }
  }

  @override
  Stream<String> generateStream(String prompt) {
    if (_engine == null) {
      throw Exception(
        'MediaPipeEngine: Model not loaded. Call loadModel() first.',
      );
    }
    // Using generateResponse based on probe results (returns Stream<String>)
    return _engine!.generateResponse(prompt);
  }

  @override
  Future<void> dispose() async {
    _engine?.dispose();
    _engine = null;
  }
}
