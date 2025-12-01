import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = AppUser(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? profileImage,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (profileImage != null) updates['profileImage'] = profileImage;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      rethrow;
    }
  }
}

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Post comment baru (Sekarang menerima animeTitle)
  Future<String> postComment({
    required String animeSlug,
    required String animeTitle, // ✅ TAMBAHAN PENTING
    required String userId,
    required String username,
    required String userEmail,
    String? userProfileImage,
    required String content,
    required double rating,
  }) async {
    try {
      final docRef = await _firestore.collection('comments').add({
        'animeSlug': animeSlug,
        'animeTitle': animeTitle, // ✅ Simpan judul ke database
        'userId': userId,
        'username': username,
        'userEmail': userEmail,
        'userProfileImage': userProfileImage,
        'content': content,
        'rating': rating,
        'createdAt': Timestamp.now(),
        'likes': 0,
        'likedBy': [],
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Ambil comments untuk anime tertentu
  Stream<List<AnimeComment>> getCommentsForAnime(String animeSlug) {
    return _firestore
        .collection('comments')
        .where('animeSlug', isEqualTo: animeSlug)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AnimeComment.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Ambil comments oleh user tertentu
  Stream<List<AnimeComment>> getCommentsByUser(String userId) {
    return _firestore
        .collection('comments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AnimeComment.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> toggleLikeComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      final doc = await commentRef.get();

      if (!doc.exists) return;

      final likedBy = List<String>.from(doc['likedBy'] as List? ?? []);
      final currentLikes = doc['likes'] as int? ?? 0;

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        await commentRef.update({
          'likedBy': likedBy,
          'likes': currentLikes - 1,
        });
      } else {
        likedBy.add(userId);
        await commentRef.update({
          'likedBy': likedBy,
          'likes': currentLikes + 1,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore.collection('comments').doc(commentId).get();
      if (doc.exists && doc['userId'] == userId) {
        await _firestore.collection('comments').doc(commentId).delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String userId,
    required String content,
    required double rating,
  }) async {
    try {
      final doc = await _firestore.collection('comments').doc(commentId).get();
      if (doc.exists && doc['userId'] == userId) {
        await _firestore.collection('comments').doc(commentId).update({
          'content': content,
          'rating': rating,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // ✅ INI FUNGSI YANG HILANG DAN MENYEBABKAN ERROR
  Future<void> updateCommentTitleDirectly(String commentId, String correctTitle) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'animeTitle': correctTitle,
      });
    } catch (e) {
      // ignore
    }
  }
}