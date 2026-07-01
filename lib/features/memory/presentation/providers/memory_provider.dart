import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/memory.dart';
import '../../domain/usecases/add_memory.dart';
import '../../domain/usecases/delete_memory.dart';
import '../../domain/usecases/update_memory.dart';
import '../../domain/usecases/watch_memories.dart';

/// Holds the signed-in user's memories and exposes the add-memory action.
///
/// Kept in sync with the signed-in user via [updateUser], which is called
/// from a `ChangeNotifierProxyProvider<AuthProvider, MemoryProvider>` in
/// `app.dart` whenever [AuthProvider.user] changes.
class MemoryProvider extends ChangeNotifier {
  MemoryProvider({
    required WatchMemories watchMemories,
    required AddMemory addMemory,
    required UpdateMemory updateMemory,
    required DeleteMemory deleteMemory,
  }) : _watchMemories = watchMemories,
       _addMemory = addMemory,
       _updateMemory = updateMemory,
       _deleteMemory = deleteMemory;

  final WatchMemories _watchMemories;
  final AddMemory _addMemory;
  final UpdateMemory _updateMemory;
  final DeleteMemory _deleteMemory;

  StreamSubscription<List<Memory>>? _subscription;
  String? _ownerId;

  List<Memory> _memories = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<Memory> get memories => _memories;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Re-subscribes to the given user's memories, or clears state on sign-out.
  void updateUser(AppUser? user) {
    if (user?.uid == _ownerId) return;
    _ownerId = user?.uid;
    _subscription?.cancel();
    _memories = const [];

    if (_ownerId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _subscription = _watchMemories(_ownerId!).listen((memories) {
      _memories = memories;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> addMemory({
    required String title,
    required String note,
    required double latitude,
    required double longitude,
    required double rating,
    required List<File> imageFiles,
    File? videoFile,
  }) async {
    final ownerId = _ownerId;
    if (ownerId == null) {
      _errorMessage = 'Kaydetmek için önce giriş yapmalısınız.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _addMemory(
        ownerId: ownerId,
        title: title,
        note: note,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        imageFiles: imageFiles,
        videoFile: videoFile,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Anı kaydedilirken beklenmeyen bir hata oluştu.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateMemory({
    required String memoryId,
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
    final ownerId = _ownerId;
    if (ownerId == null) {
      _errorMessage = 'Güncellemek için önce giriş yapmalısınız.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _updateMemory(
        memoryId: memoryId,
        ownerId: ownerId,
        title: title,
        note: note,
        rating: rating,
        keptPhotoUrls: keptPhotoUrls,
        removedPhotoUrls: removedPhotoUrls,
        newImageFiles: newImageFiles,
        keptVideoUrl: keptVideoUrl,
        removedVideoUrl: removedVideoUrl,
        newVideoFile: newVideoFile,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Anı güncellenirken beklenmeyen bir hata oluştu.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMemory(String memoryId) async {
    final ownerId = _ownerId;
    if (ownerId == null) {
      _errorMessage = 'Silmek için önce giriş yapmalısınız.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _deleteMemory(ownerId: ownerId, memoryId: memoryId);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Anı silinirken beklenmeyen bir hata oluştu.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
