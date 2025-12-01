import 'package:cloud_firestore/cloud_firestore.dart';

class WatchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update data history (logika standar)
  Future<void> addWatchHistory({
    required String userId,
    required String animeSlug,
    required String animeTitle,
    String? animeImage,
    String? episodeSlug,
    String? episodeTitle,
    double progress = 0.0,
  }) async {
    try {
      // Cari data yang duplikat berdasarkan animeSlug
      final existingDocs = await _firestore
          .collection('watch_history')
          .where('userId', isEqualTo: userId)
          .where('animeSlug', isEqualTo: animeSlug)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in existingDocs.docs) {
          final Map<String, dynamic> updates = {
            'animeTitle': animeTitle,
            'episodeSlug': episodeSlug,
            'episodeTitle': episodeTitle,
            'progress': progress,
            'watchedAt': Timestamp.now(),
          };
          // Hanya update gambar jika data baru valid
          if (animeImage != null && animeImage.isNotEmpty) {
            updates['animeImage'] = animeImage;
          }
          batch.update(doc.reference, updates);
        }
        await batch.commit();
      } else {
        // Buat baru
        await _firestore.collection('watch_history').add({
          'userId': userId,
          'animeSlug': animeSlug,
          'animeTitle': animeTitle,
          'animeImage': animeImage ?? '',
          'episodeSlug': episodeSlug,
          'episodeTitle': episodeTitle,
          'progress': progress,
          'watchedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      // ignore
    }
  }

  /// 🛠️ FITUR BARU: Update gambar langsung tembak ke ID dokumen (Pasti berhasil)
  Future<void> updateImageDirectly(String docId, String newImageUrl) async {
    try {
      await _firestore.collection('watch_history').doc(docId).update({
        'animeImage': newImageUrl,
      });
    } catch (e) {
      // ignore
    }
  }

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

  // Hapus satu item
  Future<void> deleteFromHistory({
    required String historyId,
    required String userId,
  }) async {
    try {
      final doc =
          await _firestore.collection('watch_history').doc(historyId).get();
      if (doc.exists && doc['userId'] == userId) {
        await _firestore.collection('watch_history').doc(historyId).delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Hapus semua (Clear History)
  Future<void> clearWatchHistory(String userId) async {
    try {
      final docs = await _firestore
          .collection('watch_history')
          .where('userId', isEqualTo: userId)
          .get();
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
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
  final double progress;
  final DateTime watchedAt;

  WatchHistory({
    required this.id,
    required this.userId,
    required this.animeSlug,
    required this.animeTitle,
    this.animeImage,
    this.episodeSlug,
    this.episodeTitle,
    this.progress = 0.0,
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
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
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
      'progress': progress,
      'watchedAt': Timestamp.fromDate(watchedAt),
    };
  }
}