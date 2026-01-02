abstract class InferenceProvider {
  String get engineKey;
  bool supportsExtension(String extension);

  /// Returns true if the current active delegate is NPU or GPU.
  bool get isHardwareAccelerated;

  Future<void> loadModel(String modelPath, {bool isAsset = false});
  Stream<String> generateStream(String prompt);
  Future<void> dispose();
}
