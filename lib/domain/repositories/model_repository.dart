abstract class ModelRepository {
  Future<String> getModelPath(String assetName);
  Future<List<String>> getAvailableModels();
}
