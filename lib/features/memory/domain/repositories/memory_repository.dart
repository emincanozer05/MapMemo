import 'dart:io';

import '../entities/memory.dart';

abstract class MemoryRepository {
  /// Emits the given owner's memories, newest first, updating live as
  /// Firestore changes.
  Stream<List<Memory>> watchMemories(String ownerId);

  /// Uploads [imageFiles]/[videoFile] to Storage, then writes the memory
  /// document to Firestore. Returns the saved [Memory].
  Future<Memory> addMemory({
    required String ownerId,
    required String title,
    required String note,
    required double latitude,
    required double longitude,
    required double rating,
    required List<File> imageFiles,
    File? videoFile,
  });
}
