import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import '../models/comment_models.dart';
import '../widgets/login_dialog.dart';

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

  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      // Show login dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const LoginDialog(),
      );

      if (result != true) return;

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✓ Login berhasil!')));
      return;
    }

    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appUser = await _authService.getUser(currentUser.uid);

      await _commentService.postComment(
        animeSlug: widget.animeSlug,
        userId: currentUser.uid,
        username: appUser?.username ?? 'Anonymous',
        userEmail: currentUser.email ?? '',
        userProfileImage: appUser?.profileImage,
        content: _contentCtrl.text.trim(),
        rating: _rating,
      );

      _contentCtrl.clear();
      setState(() => _rating = 5.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Komentar berhasil diposting!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Comment form
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info atau login button
                  if (currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: cs.primary,
                            child: Text(
                              (currentUser.email?[0] ?? 'A').toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.email ?? 'User',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Anda harus login untuk berkomentar'),
                          FilledButton.tonal(
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const LoginDialog(),
                              );

                              if (result == true && mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Login berhasil!'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),

                  if (currentUser != null) ...[
                    // Rating
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rating: ${_rating.toStringAsFixed(1)} ⭐',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: cs.primary,
                              thumbColor: cs.primary,
                            ),
                            child: Slider(
                              value: _rating,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (val) {
                                setState(() => _rating = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Textarea untuk komentar
                    TextField(
                      controller: _contentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar tentang anime ini...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 12),

                    // Tombol post
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _postComment,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isSubmitting ? 'Posting...' : 'Post Komentar',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // List komentar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<List<AnimeComment>>(
            stream: _commentService.getCommentsForAnime(widget.animeSlug),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada komentar. Jadilah yang pertama berkomentar!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final comment = comments[idx];
                  final isOwner = currentUser?.uid == comment.userId;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header komentar
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: cs.primary,
                                child: Text(
                                  (comment.username[0]).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      comment.userEmail,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              // Rating
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: cs.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment.rating}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Konten komentar
                          Text(
                            comment.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),

                          // Footer (tanggal, like, delete)
                          Row(
                            children: [
                              Text(
                                _formatDate(comment.createdAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: cs.outlineVariant),
                              ),
                              const Spacer(),
                              // Like button
                              if (currentUser != null)
                                FilledButton.tonal(
                                  onPressed: () {
                                    _commentService.toggleLikeComment(
                                      commentId: comment.id,
                                      userId: currentUser.uid,
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        comment.likedBy.contains(
                                              currentUser.uid,
                                            )
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        comment.likes.toString(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              // Delete button (hanya untuk owner)
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  iconSize: 20,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Hapus Komentar?'),
                                        content: const Text(
                                          'Komentar yang dihapus tidak bisa dipulihkan.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Batal'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              _commentService.deleteComment(
                                                commentId: comment.id,
                                                userId: currentUser!.uid,
                                              );
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
