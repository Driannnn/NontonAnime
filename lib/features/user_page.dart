import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import '../core/watch_history_service.dart';
import '../core/favorite_service.dart';
import '../models/comment_models.dart';
import '../widgets/login_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_proxy_utils.dart';
import '../utils/slug_utils.dart';
import '../widgets/common.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _authService = AuthService();
  final _commentService = CommentService();
  final _watchHistoryService = WatchHistoryService();
  final _favoriteService = FavoriteService();

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
                onPressed: () => context.go('/home'),
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
              onPressed: () => context.go('/home'),
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

              // Riwayat Tontonan
              Text(
                'Lanjut Tonton', // Ubah judul agar lebih relevan
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildWatchHistoryWidget(currentUser.uid),
              const SizedBox(height: 24),

              // Favorit
              Text(
                'Favorit',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildFavoritesWidget(currentUser.uid),
              const SizedBox(height: 24),

              // Komentar saya
              Text(
                'Komentar Saya',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildUserCommentsWidget(currentUser.uid, null),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWatchHistoryWidget(String userId) {
    return StreamBuilder<List<WatchHistory>>(
      stream: _watchHistoryService.getWatchHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var history = snapshot.data ?? [];
        final cs = Theme.of(context).colorScheme;

        // Dedup: hanya ambil yang terbaru per anime
        final Map<String, WatchHistory> uniqueHistory = {};
        for (final item in history) {
          if (!uniqueHistory.containsKey(item.animeSlug)) {
            uniqueHistory[item.animeSlug] = item;
          }
        }
        history = uniqueHistory.values.toList();

        if (history.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Anda belum menonton anime. Mulai menonton sekarang!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final item = history[idx];

              return GestureDetector(
                onTap: () {
                  // ✅ LOGIKA NAVIGASI BARU: LANJUT NONTON
                  // Cek apakah ada data episode slug
                  if (item.episodeSlug != null &&
                      item.episodeSlug!.isNotEmpty) {
                    // Normalize slug untuk jaga-jaga
                    final fixedEpSlug = normalizeAnimeSlug(item.episodeSlug!);

                    // Ke halaman Episode (Player)
                    // Kita oper 'title' dan 'animeImage' via query params
                    final titleEncoded = Uri.encodeComponent(
                      item.episodeTitle ?? 'Episode',
                    );
                    final imageEncoded = Uri.encodeComponent(
                      item.animeImage ?? '',
                    );
                    context.push(
                      '/episode/$fixedEpSlug?title=$titleEncoded&animeImage=$imageEncoded',
                    );
                  } else {
                    // Fallback: Jika data episode rusak, ke Detail Anime
                    final fixedAnimeSlug = normalizeAnimeSlug(item.animeSlug);
                    context.go('/anime/$fixedAnimeSlug');
                  }
                },
                child: SizedBox(
                  width: 140, // Sedikit diperlebar agar proporsional
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GAMBAR + PROGRESS BAR
                      Expanded(
                        child: Stack(
                          children: [
                            // 1. Gambar Background
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (item.animeImage?.isNotEmpty ?? false)
                                  ? CachedNetworkImage(
                                      imageUrl: coverProxy(item.animeImage!),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (c, url) =>
                                          const ShimmerBox(),
                                      errorWidget: (c, url, error) => Container(
                                        color: cs.surfaceVariant,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: cs.surfaceVariant,
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.movie_filter,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 4),
                                          Text("No Image"),
                                        ],
                                      ),
                                    ),
                            ),

                            // 2. Overlay Play Icon (Supaya jelas ini bisa diklik/play)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),

                            // 3. PROGRESS BAR MERAH (Indikator 'Lanjut')
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ),
                                child: LinearProgressIndicator(
                                  // Default 15% jika 0, biar terlihat 'in progress'
                                  value: item.progress > 0
                                      ? item.progress
                                      : 0.15,
                                  backgroundColor: Colors.grey.withOpacity(0.5),
                                  color: Colors.redAccent, // Warna Merah
                                  minHeight: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Judul Anime
                      Text(
                        item.animeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // Judul Episode (Misal: Episode 12)
                      if (item.episodeTitle != null)
                        Text(
                          item.episodeTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: 11, color: cs.primary),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- Widget Lainnya Tetap Sama ---

  Widget _buildFavoritesWidget(String userId) {
    return StreamBuilder<List<Favorite>>(
      stream: _favoriteService.getFavorites(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = snapshot.data ?? [];
        final cs = Theme.of(context).colorScheme;

        if (favorites.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Anda belum memiliki favorit.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final item = favorites[idx];

              return GestureDetector(
                onTap: () => context.go('/anime/${item.animeSlug}'),
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.animeImage != null
                                ? CachedNetworkImage(
                                    imageUrl: coverProxy(item.animeImage!),
                                    height: 150,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (c, url) => const ShimmerBox(),
                                    errorWidget: (c, u, e) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : Container(
                                    height: 150,
                                    width: 120,
                                    color: cs.surfaceContainerHighest,
                                    child: const Icon(Icons.image),
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () async {
                                await _favoriteService.removeFromFavorite(
                                  userId: userId,
                                  animeSlug: item.animeSlug,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          item.animeTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data ?? [];
        final cs = Theme.of(context).colorScheme;

        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Anda belum ada komentar.',
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
                        Expanded(
                          child: Text(
                            'Anime ID: ${comment.animeSlug}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: cs.primary),
                            Text(
                              '${comment.rating}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: Theme.of(context).textTheme.bodyMedium,
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
}
