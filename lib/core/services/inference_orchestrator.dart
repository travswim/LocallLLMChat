import 'package:flutter/foundation.dart';
import 'dart:async';
import 'engines/inference_provider.dart';
import 'engines/mediapipe_engine.dart';
import 'engines/litert_engine.dart';
import '../native_bridge/memory_bridge.dart';
import 'extraction_service.dart';

class InferenceOrchestrator {
  InferenceProvider? _activeEngine;
  final MediaPipeEngine _mediaPipeEngine = MediaPipeEngine();
  final LiteRTEngine _liteRTEngine = LiteRTEngine();
  final MemoryBridge _memoryBridge = MemoryBridge();
  final ExtractionService _extractionService = ExtractionService();

  bool get isHardwareAccelerated =>
      _activeEngine?.isHardwareAccelerated ?? false;
  String get activeEngineKey => _activeEngine?.engineKey ?? 'none';

  Future<void> loadModel(String modelPath, {bool isAsset = false}) async {
    await dispose();

    // 1. Check RAM Safety
    try {
      final availableRam = await _memoryBridge.getAvailableMemory();
      debugPrint(
        'InferenceOrchestrator: Available RAM: ${availableRam / 1024 / 1024} MB',
      );

      // Simple guard: If < 500MB available, warn or throw.
      // Note: Model size check would be better if we knew the model size beforehand.
      if (availableRam != -1 && availableRam < 500 * 1024 * 1024) {
        debugPrint(
          'WARNING: Low memory detected ($availableRam bytes). Loading might fail.',
        );
        // We could throw MemoryPressureException() here if strict.
      }
    } catch (e) {
      debugPrint(
        'InferenceOrchestrator: Memory check passed with warning or ignored: $e',
      );
    }

    // 2. Extract Asset if needed
    String effectivePath = modelPath;
    if (isAsset) {
      try {
        final fileName = modelPath.split('/').last;
        debugPrint('InferenceOrchestrator: Extracting asset $modelPath...');
        effectivePath = await _extractionService.extractModelIfNeeded(
          modelPath,
          fileName,
        );
        debugPrint('InferenceOrchestrator: Model extracted to $effectivePath');
      } catch (e) {
        throw Exception('Failed to extract model asset: $e');
      }
    }

    // 3. Route based on extension/type
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
      // We pass the effective (extracted) path and isAsset: false because we handled it.
      await _activeEngine!.loadModel(effectivePath, isAsset: false);
      await _warmUp();
    } catch (e) {
      debugPrint(
        'InferenceOrchestrator: Load failed for ${_activeEngine!.engineKey}. Error: $e',
      );
      // Potential fallback logic can be added here
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
