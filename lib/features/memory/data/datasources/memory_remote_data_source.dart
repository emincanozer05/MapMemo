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

  Future<MemoryModel> updateMemory({
    required String memoryId,
    required String ownerId,
    required String title,
    required String note,
    required double rating,
    required List<String> keptPhotoUrls,
    required List<String> removedPhotoUrls,
    required List<File> newImageFiles,
    String? keptVideoUrl,
    String? removedVideoUrl,
    File? newVideoFile,
  });

  Future<void> deleteMemory({
    required String ownerId,
    required String memoryId,
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

  @override
  Future<MemoryModel> updateMemory({
    required String memoryId,
    required String ownerId,
    required String title,
    required String note,
    required double rating,
    required List<String> keptPhotoUrls,
    required List<String> removedPhotoUrls,
    required List<File> newImageFiles,
    String? keptVideoUrl,
    String? removedVideoUrl,
    File? newVideoFile,
  }) async {
    try {
      for (final url in removedPhotoUrls) {
        await _deleteByUrl(url);
      }

      final photoUrls = [...keptPhotoUrls];
      for (var i = 0; i < newImageFiles.length; i++) {
        photoUrls.add(
          await _upload(
            ownerId: ownerId,
            memoryId: memoryId,
            file: newImageFiles[i],
            fileName:
                'photo_${DateTime.now().microsecondsSinceEpoch}_$i'
                '${_extensionOf(newImageFiles[i].path)}',
          ),
        );
      }

      String? videoUrl;
      if (newVideoFile != null) {
        if (removedVideoUrl != null) {
          await _deleteByUrl(removedVideoUrl);
        }
        videoUrl = await _upload(
          ownerId: ownerId,
          memoryId: memoryId,
          file: newVideoFile,
          fileName:
              'video_${DateTime.now().microsecondsSinceEpoch}'
              '${_extensionOf(newVideoFile.path)}',
        );
      } else {
        if (removedVideoUrl != null) {
          await _deleteByUrl(removedVideoUrl);
        }
        videoUrl = keptVideoUrl;
      }

      final docRef = _memories.doc(memoryId);
      await docRef.update({
        'title': title,
        'note': note,
        'rating': rating,
        'photoUrls': photoUrls,
        'videoUrl': videoUrl,
      });

      final saved = await docRef.get();
      return MemoryModel.fromFirestore(saved);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Anı güncellenirken bir hata oluştu.');
    }
  }

  @override
  Future<void> deleteMemory({
    required String ownerId,
    required String memoryId,
  }) async {
    try {
      final folderRef = _storage.ref('memories/$ownerId/$memoryId');
      final listing = await folderRef.listAll();
      await Future.wait(listing.items.map((item) => item.delete()));
      await _memories.doc(memoryId).delete();
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? 'Anı silinirken bir hata oluştu.');
    }
  }

  Future<void> _deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException {
      // Dosya zaten silinmişse (ör. daha önceki bir denemede) sessizce
      // devam et — kullanıcının işlemi engellenmemeli.
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
