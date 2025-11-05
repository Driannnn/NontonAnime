import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign Up dengan email dan password
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

      // Simpan ke Firestore
      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In dengan email dan password
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

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Ambil user dari Firestore
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

  /// Update profil user
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

  /// Post comment baru
  Future<String> postComment({
    required String animeSlug,
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

  /// Like/Unlike comment
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
        // Unlike
        likedBy.remove(userId);
        await commentRef.update({
          'likedBy': likedBy,
          'likes': currentLikes - 1,
        });
      } else {
        // Like
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

  /// Delete comment (hanya owner atau admin)
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

  /// Update comment (hanya owner)
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
}
