import 'package:flutter/services.dart';

class MemoryException implements Exception {
  final String message;
  MemoryException(this.message);
  @override
  String toString() => 'MemoryException: $message';
}

class MemoryPressureException extends MemoryException {
  MemoryPressureException()
    : super('Critical low memory state detected by OS. Operation aborted.');
}

class MemoryBridge {
  static const MethodChannel _channel = MethodChannel('com.example.app/memory');

  Future<int> getAvailableMemory() async {
    try {
      final int result = await _channel.invokeMethod('getAvailableMemory');
      if (result == -1) {
        throw MemoryPressureException();
      }
      return result;
    } on PlatformException catch (e) {
      throw MemoryException('Failed to query native memory: ${e.message}');
    }
  }
}
