import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/memory.dart';

/// Maps between a Firestore `memories/{id}` document and the domain
/// [Memory] entity. This is the only file allowed to know the Firestore
/// field names/types.
class MemoryModel extends Memory {
  const MemoryModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.note,
    required super.latitude,
    required super.longitude,
    required super.rating,
    required super.photoUrls,
    required super.createdAt,
    super.videoUrl,
  });

  factory MemoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MemoryModel(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      note: data['note'] as String? ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      rating: (data['rating'] as num).toDouble(),
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? const []),
      videoUrl: data['videoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'photoUrls': photoUrls,
      'videoUrl': videoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
