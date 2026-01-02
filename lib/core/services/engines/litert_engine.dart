import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'inference_provider.dart';

class LiteRTEngine implements InferenceProvider {
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  bool _isHardwareAccelerated = false;

  @override
  String get engineKey => 'litert';

  @override
  bool get isHardwareAccelerated => _isHardwareAccelerated;

  @override
  bool supportsExtension(String extension) {
    return extension == '.tflite';
  }

  @override
  Future<void> loadModel(String modelPath, {bool isAsset = false}) async {
    if (_interpreter != null) {
      await dispose();
    }

    try {
      final options = InterpreterOptions();
      // Simple thread configuration for now.
      // Hardware delegates like GpuDelegateV2 are available in tflite_flutter but require specific setup.
      // We will default to CPU/XNNPACK (often enabled by default) for stability unless configured.
      options.threads = 4;

      if (isAsset) {
        _interpreter = await Interpreter.fromAsset(modelPath, options: options);
      } else {
        _interpreter = Interpreter.fromFile(File(modelPath), options: options);
      }

      // Create IsolateInterpreter for non-blocking inference
      _isolateInterpreter = await IsolateInterpreter.create(
        address: _interpreter!.address,
      );

      // Check delegates to set isHardwareAccelerated flag?
      // _interpreter.getOutputTensor(0).type ...
      // For now, assume CPU unless we explicitly add GPU delegate
      _isHardwareAccelerated = false;
    } catch (e) {
      throw Exception('LiteRTEngine: Failed to load model: $e');
    }
  }

  @override
  Stream<String> generateStream(String prompt) async* {
    if (_isolateInterpreter == null) {
      throw Exception('LiteRTEngine: Model not initialized');
    }

    // TODO: Implement Tokenizer/Detokenizer for specific TFLite models.
    // Raw LiteRT models expect TensorBuffers, not Strings.
    // This requires a specific model contract (e.g. Bert, Gemma-LiteRT).

    // For demonstration/fallback, we yield a placeholder.
    debugPrint(
      'LiteRTEngine: generateStream called. Tokenization not implemented.',
    );
    yield "LiteRTEngine: Raw inference not fully implemented without Tokenizer.";
  }

  @override
  Future<void> dispose() async {
    // IsolateInterpreter doesn't strictly need dispose if it shares address,
    // but good practice if wrapper has it.
    // _isolateInterpreter.close(); // Wrapper might not have close.
    _interpreter?.close();
    _interpreter = null;
    _isolateInterpreter = null;
  }
}
