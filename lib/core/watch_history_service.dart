import 'package:cloud_firestore/cloud_firestore.dart';

class WatchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tambah atau update riwayat tontonan (unik per anime, no duplicate)
  Future<void> addWatchHistory({
    required String userId,
    required String animeSlug,
    required String animeTitle,
    String? animeImage,
    String? episodeSlug,
    String? episodeTitle,
  }) async {
    try {
      // Cek apakah anime sudah ada di history
      final existingDocs = await _firestore
          .collection('watch_history')
          .where('userId', isEqualTo: userId)
          .where('animeSlug', isEqualTo: animeSlug)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        // Update entry yang sudah ada (update timestamp)
        await existingDocs.docs.first.reference.update({
          'animeTitle': animeTitle,
          'animeImage': animeImage,
          'episodeSlug': episodeSlug,
          'episodeTitle': episodeTitle,
          'watchedAt': Timestamp.now(),
        });
      } else {
        // Tambah entry baru
        await _firestore.collection('watch_history').add({
          'userId': userId,
          'animeSlug': animeSlug,
          'animeTitle': animeTitle,
          'animeImage': animeImage,
          'episodeSlug': episodeSlug,
          'episodeTitle': episodeTitle,
          'watchedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Ambil riwayat tontonan user (terbaru terlebih dahulu)
  Stream<List<WatchHistory>> getWatchHistory(String userId) {
    return _firestore
        .collection('watch_history')
        .where('userId', isEqualTo: userId)
        .orderBy('watchedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WatchHistory.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Hapus item dari riwayat tontonan
  Future<void> deleteFromHistory({
    required String historyId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('watch_history')
          .doc(historyId)
          .get();

      if (doc.exists && doc['userId'] == userId) {
        await _firestore.collection('watch_history').doc(historyId).delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hapus semua riwayat tontonan user
  Future<void> clearWatchHistory(String userId) async {
    try {
      final docs = await _firestore
          .collection('watch_history')
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

class WatchHistory {
  final String id;
  final String userId;
  final String animeSlug;
  final String animeTitle;
  final String? animeImage;
  final String? episodeSlug;
  final String? episodeTitle;
  final DateTime watchedAt;

  WatchHistory({
    required this.id,
    required this.userId,
    required this.animeSlug,
    required this.animeTitle,
    this.animeImage,
    this.episodeSlug,
    this.episodeTitle,
    required this.watchedAt,
  });

  factory WatchHistory.fromMap(String id, Map<String, dynamic> data) {
    return WatchHistory(
      id: id,
      userId: data['userId'] ?? '',
      animeSlug: data['animeSlug'] ?? '',
      animeTitle: data['animeTitle'] ?? '',
      animeImage: data['animeImage'],
      episodeSlug: data['episodeSlug'],
      episodeTitle: data['episodeTitle'],
      watchedAt: (data['watchedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'animeSlug': animeSlug,
      'animeTitle': animeTitle,
      'animeImage': animeImage,
      'episodeSlug': episodeSlug,
      'episodeTitle': episodeTitle,
      'watchedAt': Timestamp.fromDate(watchedAt),
    };
  }
}
