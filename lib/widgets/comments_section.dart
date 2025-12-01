import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart'; // Perlu Dio untuk cari judul
import '../core/auth_service.dart';
import '../models/comment_models.dart';
import '../models/anime_models.dart';
import '../core/api_client.dart'; // Untuk fetchAnimeDetail
import '../widgets/login_dialog.dart';
import '../utils/slug_utils.dart'; // Untuk normalisasi slug

class CommentsSection extends StatefulWidget {
  final String animeSlug;
  final String animeTitleFallback;

  const CommentsSection({
    super.key,
    required this.animeSlug,
    required this.animeTitleFallback,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _authService = AuthService();
  final _commentService = CommentService();
  final _contentCtrl = TextEditingController();
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  // ✅ HELPER AVATAR YANG BENAR (Support Base64 & Network)
  Widget _buildAvatar(String? imageUrl, String username, {double radius = 20}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // 1. Cek Base64 (Foto dari Galeri HP)
      if (imageUrl.startsWith('data:image')) {
        try {
          final base64String = imageUrl.split(',')[1];
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes), // Tampilkan gambar asli
          );
        } catch (_) {
          // Fallback jika gagal decode
        }
      } 
      // 2. Cek Network URL
      else {
        return CircleAvatar(
          radius: radius,
          backgroundImage: CachedNetworkImageProvider(imageUrl),
          onBackgroundImageError: (_, __) {},
        );
      }
    }
    
    // 3. Fallback Inisial Nama (Jika tidak ada foto)
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blueAccent,
      child: Text(
        (username.isNotEmpty ? username[0] : '?').toUpperCase(),
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold,
          fontSize: radius,
        ),
      ),
    );
  }

  // Helper: Cari Judul Asli Sebelum Posting
  Future<String> _getCorrectTitle(String slug, String fallback) async {
    if (fallback.isNotEmpty && 
        !fallback.contains('-') && 
        fallback != slug && 
        !fallback.toLowerCase().contains('episode')) {
      return fallback;
    }

    try {
      String searchKeyword = normalizeAnimeSlug(slug);
      if (searchKeyword.contains('-episode-')) {
        searchKeyword = searchKeyword.split('-episode-')[0];
      }

      // Coba fetch detail anime
      try {
        final rawData = await fetchAnimeDetail(searchKeyword);
        final detail = AnimeDetailDisplay.fromMap(rawData, null);
        if (detail.title != null && detail.title!.isNotEmpty) return detail.title!;
      } catch (_) {}

      // Fallback Search
      final res = await _dio.get('/anime/search/$searchKeyword');
      final data = res.data;
      List rawList = [];
      if (data is Map && data['data'] is List) rawList = data['data'];
      else if (data is Map && data['search_results'] is List) rawList = data['search_results'];
      
      if (rawList.isNotEmpty) {
        return rawList.first['title'];
      }
    } catch (_) {}

    return fallback;
  }

  Future<void> _postComment() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const LoginDialog(),
      );
      if (result == true && mounted) setState(() {});
      return;
    }

    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Komentar kosong')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appUser = await _authService.getUser(currentUser.uid);
      
      // Cari judul yang benar sebelum kirim
      String correctTitle = await _getCorrectTitle(widget.animeSlug, widget.animeTitleFallback);

      await _commentService.postComment(
        animeSlug: widget.animeSlug,
        animeTitle: correctTitle,
        userId: currentUser.uid,
        username: appUser?.username ?? 'Anonymous',
        userEmail: currentUser.email ?? '',
        userProfileImage: appUser?.profileImage, // Kirim foto profil terbaru
        content: _contentCtrl.text.trim(),
        rating: _rating,
      );

      _contentCtrl.clear();
      setState(() => _rating = 5.0);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Terkirim!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}h lalu';
    if (diff.inDays < 7) return '${diff.inDays}d lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentUser = _authService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.comment, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Komentar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Form Komentar (Card)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FutureBuilder<AppUser?>(
                        future: _authService.getUser(currentUser.uid),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          // Avatar User Login
                          return Row(
                            children: [
                              _buildAvatar(user?.profileImage, user?.username ?? 'User', radius: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.username ?? 'Loading...',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      currentUser.email ?? '',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Anda harus login untuk berkomentar'),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const LoginDialog(),
                              );
                              if (mounted) setState(() {});
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),

                  if (currentUser != null) ...[
                    // Rating & Slider
                    Row(
                      children: [
                        const Text("Rating: "),
                        Text(
                          _rating.toStringAsFixed(1),
                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                      ],
                    ),
                    Slider(
                      value: _rating,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (val) => setState(() => _rating = val),
                    ),

                    // TextField
                    TextField(
                      controller: _contentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tulis tanggapanmu...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tombol Kirim
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _postComment,
                        icon: _isSubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, size: 18),
                        label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // List Komentar (TAMPILAN DIPERBAIKI)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<List<AnimeComment>>(
            stream: _commentService.getCommentsForAnime(widget.animeSlug),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada komentar.\nJadilah yang pertama!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final comment = comments[idx];
                  final isOwner = currentUser?.uid == comment.userId;
                  final isLiked = currentUser != null && comment.likedBy.contains(currentUser.uid);

                  // 🔥 FITUR REAL-TIME AVATAR 🔥
                  // Ambil data user terbaru agar foto selalu update
                  return FutureBuilder<AppUser?>(
                    future: _authService.getUser(comment.userId), 
                    builder: (context, userSnap) {
                      final latestUser = userSnap.data;
                      final displayImage = latestUser?.profileImage ?? comment.userProfileImage;
                      final displayName = latestUser?.username ?? comment.username;

                      return Card(
                        elevation: 0.5,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Avatar, Nama, Rating, Tanggal
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  _buildAvatar(displayImage, displayName, radius: 20),
                                  const SizedBox(width: 10),
                                  
                                  // Nama & Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                displayName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Badge Rating
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.star, size: 12, color: Colors.orange),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    comment.rating.toString(),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          _formatDate(comment.createdAt),
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tombol Hapus (Owner Only)
                                  if (isOwner)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      tooltip: 'Hapus',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Hapus Komentar?'),
                                            content: const Text('Tindakan ini tidak bisa dibatalkan.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                              FilledButton(
                                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () {
                                                  _commentService.deleteComment(commentId: comment.id, userId: currentUser!.uid);
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Isi Komentar
                              Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
                              
                              const SizedBox(height: 12),

                              // Footer: Tombol Like
                              Row(
                                children: [
                                  InkWell(
                                    onTap: currentUser == null
                                        ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login untuk menyukai')))
                                        : () => _commentService.toggleLikeComment(commentId: comment.id, userId: currentUser.uid),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isLiked ? Colors.pink.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isLiked ? Icons.favorite : Icons.favorite_border,
                                            size: 18,
                                            color: isLiked ? Colors.pink : Colors.grey[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${comment.likes}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isLiked ? Colors.pink : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}