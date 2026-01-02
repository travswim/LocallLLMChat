import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ExtractionService {
  static const int _chunkSize = 1024 * 1024; // 1MB chunks

  Future<String> extractModelIfNeeded(
    String assetPath,
    String modelName,
  ) async {
    final docsDir = await getApplicationSupportDirectory();
    final file = File('${docsDir.path}/$modelName');

    // Check existence and size to avoid re-copying
    if (await file.exists()) {
      try {
        final assetData = await rootBundle.load(assetPath);
        if (await file.length() == assetData.lengthInBytes) {
          return file.path; // Already extracted
        }
      } catch (e) {
        // Asset might be too big to loadInBytes for check, assume if exists it's good
        // Or implement a meta-data check. For now, rely on file existence.
        return file.path;
      }
    }

    // Streaming Copy
    final byteData = await rootBundle.load(assetPath);
    final raf = await file.open(mode: FileMode.write);

    try {
      int offset = 0;
      final total = byteData.lengthInBytes;

      while (offset < total) {
        final end = (offset + _chunkSize < total) ? offset + _chunkSize : total;
        final chunk = byteData.buffer.asUint8List(offset, end - offset);
        await raf.writeFrom(chunk);
        offset = end;
      }
    } finally {
      await raf.close();
    }

    return file.path;
  }
}
