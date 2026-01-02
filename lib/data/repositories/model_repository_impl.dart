import '../../domain/repositories/model_repository.dart';
import '../../core/services/extraction_service.dart';

class ModelRepositoryImpl implements ModelRepository {
  final ExtractionService _extractionService;

  ModelRepositoryImpl(this._extractionService);

  @override
  Future<List<String>> getAvailableModels() async {
    //In a real app, this might list assets or downloaded files.
    // For now, we return a hardcoded list of expected assets.
    return ['gemma-2b-it-gpu-int4.bin', 'model.tflite'];
  }

  @override
  Future<String> getModelPath(String assetName) async {
    // Delegates to ExtractionService to copy asset to storage if needed
    // Assets are usually in 'assets/models/' in pubspec
    // But implementation plan implies rootBundle loading.

    // We assume asset key is 'assets/models/$assetName' or just '$assetName' depending on pubspec.
    // Let's assume 'assets/$assetName' for safety or just pass the name if ExtractionService handles pathing.
    // Looking at ExtractionService: "rootBundle.load(assetPath)".

    return _extractionService.extractModelIfNeeded(
      'assets/$assetName',
      assetName,
    );
  }
}
