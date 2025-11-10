import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import '../models/comment_models.dart';
import '../widgets/login_dialog.dart';
import 'package:go_router/go_router.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _authService = AuthService();
  final _commentService = CommentService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final currentUser = _authService.currentUser;

        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.push('/home'),
              ),
              title: const Text('Profil'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  const Text('Anda belum login'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const LoginDialog(),
                      );

                      if (result == true && mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Login berhasil!')),
                        );
                      }
                    },
                    child: const Text('Login Sekarang'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.push('/home'),
            ),
            title: const Text('Profil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout?'),
                      content: const Text('Anda akan keluar dari akun ini.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () {
                            _authService.signOut();
                            Navigator.pop(ctx);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: cs.primary,
                            child: Text(
                              (currentUser.email?[0] ?? 'A').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<AppUser?>(
                                  future: _authService.getUser(currentUser.uid),
                                  builder: (ctx, snap) {
                                    final user = snap.data;
                                    return Text(
                                      user?.username ?? 'User',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser.email ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Komentar saya
              Text(
                'Komentar Saya',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // List komentar user
              _buildUserCommentsWidget(
                currentUser.uid,
                null, // appUser tidak diperlukan
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserCommentsWidget(String userId, AppUser? appUser) {
    return StreamBuilder<List<AnimeComment>>(
      stream: _commentService.getCommentsByUser(userId),
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
        final cs = Theme.of(context).colorScheme;

        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Anda belum ada komentar. Mulai berkomentar di halaman episode!',
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

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Anime ID: ${comment.animeSlug}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.outlineVariant),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: cs.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.rating}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatDate(comment.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.outlineVariant),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.favorite, size: 16, color: cs.primary),
                            const SizedBox(width: 4),
                            Text(
                              comment.likes.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
