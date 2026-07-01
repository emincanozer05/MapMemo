import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/error/app_exceptions.dart';
import '../models/memory_model.dart';

abstract class MemoryRemoteDataSource {
  Stream<List<MemoryModel>> watchMemories(String ownerId);

  Future<MemoryModel> addMemory({
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

class MemoryRemoteDataSourceImpl implements MemoryRemoteDataSource {
  MemoryRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _memories =>
      _firestore.collection('memories');

  @override
  Stream<List<MemoryModel>> watchMemories(String ownerId) {
    return _memories
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MemoryModel.fromFirestore).toList(),
        );
  }

  @override
  Future<MemoryModel> addMemory({
    required String ownerId,
    required String title,
    required String note,
    required double latitude,
    required double longitude,
    required double rating,
    required List<File> imageFiles,
    File? videoFile,
  }) async {
    try {
      final docRef = _memories.doc();

      final photoUrls = <String>[];
      for (var i = 0; i < imageFiles.length; i++) {
        photoUrls.add(
          await _upload(
            ownerId: ownerId,
            memoryId: docRef.id,
            file: imageFiles[i],
            fileName: 'photo_$i${_extensionOf(imageFiles[i].path)}',
          ),
        );
      }

      String? videoUrl;
      if (videoFile != null) {
        videoUrl = await _upload(
          ownerId: ownerId,
          memoryId: docRef.id,
          file: videoFile,
          fileName: 'video${_extensionOf(videoFile.path)}',
        );
      }

      final model = MemoryModel(
        id: docRef.id,
        ownerId: ownerId,
        title: title,
        note: note,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        photoUrls: photoUrls,
        videoUrl: videoUrl,
        createdAt: DateTime.now(),
      );
      await docRef.set(model.toFirestore());

      final saved = await docRef.get();
      return MemoryModel.fromFirestore(saved);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Anı kaydedilirken bir hata oluştu.');
    }
  }

  Future<String> _upload({
    required String ownerId,
    required String memoryId,
    required File file,
    required String fileName,
  }) async {
    final ref = _storage.ref('memories/$ownerId/$memoryId/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  String _extensionOf(String path) {
    final dotIndex = path.lastIndexOf('.');
    return dotIndex == -1 ? '' : path.substring(dotIndex);
  }
}
