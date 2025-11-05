import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk User
class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? profileImage;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImage,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? 'Anonymous',
      email: map['email'] as String? ?? '',
      profileImage: map['profileImage'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Model untuk Comment
class AnimeComment {
  final String id;
  final String animeSlug;
  final String userId;
  final String username;
  final String userEmail;
  final String? userProfileImage;
  final String content;
  final double rating; // 1-10
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy; // UID yang sudah like

  AnimeComment({
    required this.id,
    required this.animeSlug,
    required this.userId,
    required this.username,
    required this.userEmail,
    this.userProfileImage,
    required this.content,
    required this.rating,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  factory AnimeComment.fromMap(String docId, Map<String, dynamic> map) {
    return AnimeComment(
      id: docId,
      animeSlug: map['animeSlug'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? 'Anonymous',
      userEmail: map['userEmail'] as String? ?? '',
      userProfileImage: map['userProfileImage'] as String?,
      content: map['content'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likes: map['likes'] as int? ?? 0,
      likedBy: List<String>.from(map['likedBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'animeSlug': animeSlug,
      'userId': userId,
      'username': username,
      'userEmail': userEmail,
      'userProfileImage': userProfileImage,
      'content': content,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
    };
  }
}
