import 'package:flutter/foundation.dart';
import 'dart:async';
import 'engines/inference_provider.dart';
import 'engines/mediapipe_engine.dart';
import 'engines/litert_engine.dart';

class InferenceOrchestrator {
  InferenceProvider? _activeEngine;
  final MediaPipeEngine _mediaPipeEngine = MediaPipeEngine();
  final LiteRTEngine _liteRTEngine = LiteRTEngine();

  bool get isHardwareAccelerated =>
      _activeEngine?.isHardwareAccelerated ?? false;
  String get activeEngineKey => _activeEngine?.engineKey ?? 'none';

  Future<void> loadModel(String modelPath, {bool isAsset = false}) async {
    await dispose();

    // Route based on extension/type
    if (_mediaPipeEngine.supportsExtension(modelPath.split('.').last)) {
      _activeEngine = _mediaPipeEngine;
    } else if (_liteRTEngine.supportsExtension(modelPath.split('.').last)) {
      _activeEngine = _liteRTEngine;
    } else {
      // Default to MediaPipe for .bin/unspecified (usually GenAI)
      _activeEngine = _mediaPipeEngine;
    }

    debugPrint('InferenceOrchestrator: Routing to ${_activeEngine!.engineKey}');

    try {
      await _activeEngine!.loadModel(modelPath, isAsset: isAsset);
      await _warmUp();
    } catch (e) {
      debugPrint(
        'InferenceOrchestrator: Load failed for ${_activeEngine!.engineKey}. Error: $e',
      );
      // Potential fallback logic here (e.g., if MediaPipe fails, try LiteRT?)
      rethrow;
    }
  }

  Future<void> _warmUp() async {
    if (_activeEngine == null) return;
    try {
      debugPrint('InferenceOrchestrator: Warming up...');
      // Minimal warm-up prompt
      final stream = _activeEngine!.generateStream(".");
      await stream.first;
      debugPrint('InferenceOrchestrator: Warm-up complete.');
    } catch (e) {
      debugPrint('InferenceOrchestrator: Warm-up failed: $e');
      // If hardware delegate failed, the Engine itself should have handled fallback (as per MediaPipeEngine implementation).
      // But if it crits, we might need to handle it.
    }
  }

  Stream<String> generateStream(String prompt) {
    if (_activeEngine == null) {
      throw Exception('No model loaded.');
    }
    return _activeEngine!.generateStream(prompt);
  }

  Future<void> dispose() async {
    await _activeEngine?.dispose();
    _activeEngine = null;
  }
}
