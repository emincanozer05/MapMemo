/// A saved place/memory: a map location plus the note, rating and media the
/// user attached to it. Deliberately has no Firestore or Google Maps types
/// so the domain layer stays plugin-free.
class Memory {
  const Memory({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.note,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.photoUrls,
    required this.createdAt,
    this.videoUrl,
  });

  final String id;
  final String ownerId;
  final String title;
  final String note;
  final double latitude;
  final double longitude;

  /// 1.0 to 5.0.
  final double rating;
  final List<String> photoUrls;
  final String? videoUrl;
  final DateTime createdAt;
}
