import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tambah anime ke favorit
  Future<void> addToFavorite({
    required String userId,
    required String animeSlug,
    required String animeTitle,
    String? animeImage,
  }) async {
    try {
      await _firestore.collection('favorites').add({
        'userId': userId,
        'animeSlug': animeSlug,
        'animeTitle': animeTitle,
        'animeImage': animeImage,
        'addedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Hapus dari favorit
  Future<void> removeFromFavorite({
    required String userId,
    required String animeSlug,
  }) async {
    try {
      final docs = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('animeSlug', isEqualTo: animeSlug)
          .get();

      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Ambil daftar favorit user
  Stream<List<Favorite>> getFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Favorite.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Cek apakah anime sudah di favorit
  Future<bool> isFavorite({
    required String userId,
    required String animeSlug,
  }) async {
    try {
      final docs = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('animeSlug', isEqualTo: animeSlug)
          .get();

      return docs.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Hapus semua favorit user
  Future<void> clearFavorites(String userId) async {
    try {
      final docs = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}

class Favorite {
  final String id;
  final String userId;
  final String animeSlug;
  final String animeTitle;
  final String? animeImage;
  final DateTime addedAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.animeSlug,
    required this.animeTitle,
    this.animeImage,
    required this.addedAt,
  });

  factory Favorite.fromMap(String id, Map<String, dynamic> data) {
    return Favorite(
      id: id,
      userId: data['userId'] ?? '',
      animeSlug: data['animeSlug'] ?? '',
      animeTitle: data['animeTitle'] ?? '',
      animeImage: data['animeImage'],
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'animeSlug': animeSlug,
      'animeTitle': animeTitle,
      'animeImage': animeImage,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
