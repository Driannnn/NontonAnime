import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';

// Imports internal
import '../core/auth_service.dart';
import '../core/watch_history_service.dart';
import '../core/favorite_service.dart';
import '../core/api_client.dart';
import '../models/comment_models.dart';
import '../models/anime_models.dart';
import '../widgets/login_dialog.dart';
import '../widgets/edit_profile_dialog.dart';
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

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  final Set<String> _repairingIds = {};
  final Set<String> _repairingCommentIds = {};

  // --- WIDGET HELPER: AVATAR ---
  Widget _defaultAvatar(ColorScheme cs, User currentUser) {
    return CircleAvatar(
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
    );
  }

  Widget _buildProfileAvatar(ColorScheme cs, User currentUser) {
    return FutureBuilder<AppUser?>(
      future: _authService.getUser(currentUser.uid),
      builder: (ctx, snap) {
        final profileImage = snap.data?.profileImage;
        if (profileImage != null && profileImage.isNotEmpty) {
          if (profileImage.startsWith('data:image')) {
            try {
              final bytes = base64Decode(profileImage.split(',')[1]);
              return CircleAvatar(
                radius: 40,
                backgroundImage: MemoryImage(bytes),
              );
            } catch (e) {
              return _defaultAvatar(cs, currentUser);
            }
          } else {
            return CircleAvatar(
              radius: 40,
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: CachedNetworkImageProvider(
                profileImage,
                errorListener: (_) {},
              ),
              child: null,
            );
          }
        }
        return _defaultAvatar(cs, currentUser);
      },
    );
  }

  // --- LOGIKA HELPER & AUTO-REPAIR ---

  String _formatSlugToTitle(String slug) {
    if (slug.isEmpty) return 'Unknown Title';
    final text = slug.replaceAll('-', ' ');
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return "${word[0].toUpperCase()}${word.substring(1)}";
        })
        .join(' ');
  }

  /// Helper: Search Title (Kunci perbaikan "Uwmf")
  Future<String?> _searchTitleBySlug(String keyword) async {
    try {
      // Search api
      final res = await _dio.get('/anime/search/$keyword');
      final data = res.data;
      List rawList = [];
      if (data is Map && data['data'] is List) {
        rawList = data['data'];
      } else if (data is Map && data['search_results'] is List) {
        rawList = data['search_results'];
      } else if (data is List) {
        rawList = data;
      }

      if (rawList.isNotEmpty) {
        final firstItem = Map<String, dynamic>.from(rawList.first);
        return firstItem['title'];
      }
    } catch (_) {}
    return null;
  }

  /// 🛠️ AUTO-REPAIR: Gambar History
  Future<void> _repairMissingImage(WatchHistory item) async {
    if (_repairingIds.contains(item.id)) return;
    _repairingIds.add(item.id);

    try {
      String slug = normalizeAnimeSlug(item.animeSlug);
      if (slug.contains('-episode-')) slug = slug.split('-episode-')[0];

      // 1. Coba fetch detail langsung
      try {
        final rawData = await fetchAnimeDetail(slug);
        final detail = AnimeDetailDisplay.fromMap(rawData, null);
        if (detail.imageUrl != null && detail.imageUrl!.isNotEmpty) {
          await _watchHistoryService.updateImageDirectly(
            item.id,
            detail.imageUrl!,
          );
          return;
        }
      } catch (_) {}

      // 2. Jika gagal, coba search title dulu, lalu ambil gambar dari hasil search
      final searchRes = await _dio.get('/anime/search/$slug');
      // ... (logika extraksi gambar search bisa ditambahkan disini jika perlu)
    } catch (e) {
      // ignore
    } finally {
      _repairingIds.remove(item.id);
    }
  }

  /// 🛠️ AUTO-REPAIR: Judul Komentar (FIXED LOGIC)
  Future<void> _repairCommentTitle(AnimeComment comment) async {
    if (_repairingCommentIds.contains(comment.id)) return;
    _repairingCommentIds.add(comment.id);

    try {
      String foundTitle = '';
      String keyword = normalizeAnimeSlug(comment.animeSlug);
      if (keyword.contains('-episode-'))
        keyword = keyword.split('-episode-')[0];

      // STEP 1: Coba Fetch Anime Detail (Priority 1)
      // Ini akan berhasil untuk "kimi-to-koete..." tapi gagal untuk "uwmf"
      try {
        final rawData = await fetchAnimeDetail(keyword);
        final detail = AnimeDetailDisplay.fromMap(rawData, null);
        if (detail.title != null &&
            detail.title!.isNotEmpty &&
            detail.title != 'No Title') {
          foundTitle = detail.title!;
        }
      } catch (_) {}

      // STEP 2: Jika Gagal, WAJIB SEARCH (Priority 2)
      // "uwmf" akan masuk sini. Search "uwmf" -> Dapat "Utagoe wa Mille-Feuille"
      if (foundTitle.isEmpty) {
        final searchResult = await _searchTitleBySlug(keyword);
        if (searchResult != null) {
          foundTitle = searchResult;
        }
      }

      // STEP 3: Update Database
      if (foundTitle.isNotEmpty &&
          foundTitle.toLowerCase() != comment.animeTitle.toLowerCase()) {
        await _commentService.updateCommentTitleDirectly(
          comment.id,
          foundTitle,
        );
      }
    } catch (e) {
      // ignore
    } finally {
      _repairingCommentIds.remove(comment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        context.go('/home');
        return false;
      },
      child: StreamBuilder(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          final currentUser = _authService.currentUser;
          if (currentUser == null) return _buildNotLoggedInView(cs);

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
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(cs, currentUser),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lanjut Tonton',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _showClearHistoryDialog(context, currentUser.uid),
                      child: const Text(
                        'Hapus History',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildWatchHistoryWidget(currentUser.uid),
                const SizedBox(height: 24),
                Text(
                  'Favorit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFavoritesWidget(currentUser.uid),
                const SizedBox(height: 24),
                Text(
                  'Komentar Saya',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildUserCommentsWidget(currentUser.uid, null),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (Widgets: NotLoggedIn, ProfileCard, Favorites SAMA PERSIS SEPERTI SEBELUMNYA)
  Widget _buildNotLoggedInView(ColorScheme cs) {
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
                if (result == true && mounted) setState(() {});
              },
              child: const Text('Login Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ColorScheme cs, User currentUser) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildProfileAvatar(cs, currentUser),
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final user = await _authService.getUser(currentUser.uid);
                    if (!context.mounted) return;
                    await showDialog(
                      context: context,
                      builder: (ctx) => EditProfileDialog(
                        currentUsername: user?.username,
                        currentProfileImage: user?.profileImage,
                      ),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesWidget(String userId) {
    return StreamBuilder<List<Favorite>>(
      stream: _favoriteService.getFavorites(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final favorites = snapshot.data!;
        if (favorites.isEmpty) return const Text('Belum ada favorit');
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final item = favorites[i];
              return GestureDetector(
                onTap: () => context.go('/anime/${item.animeSlug}'),
                child: SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: coverProxy(item.animeImage ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.animeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
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

  // --- HISTORY WIDGET ---
  Widget _buildWatchHistoryWidget(String userId) {
    return StreamBuilder<List<WatchHistory>>(
      stream: _watchHistoryService.getWatchHistory(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var history = snapshot.data!;
        final Map<String, WatchHistory> uniqueHistory = {};
        for (final item in history) {
          if (!uniqueHistory.containsKey(item.animeSlug)) {
            uniqueHistory[item.animeSlug] = item;
          }
        }
        history = uniqueHistory.values.toList();

        if (history.isEmpty) return const Text('Belum ada history.');

        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final item = history[idx];
              final hasImage =
                  item.animeImage != null && item.animeImage!.isNotEmpty;
              if (!hasImage)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _repairMissingImage(item);
                });

              return GestureDetector(
                onTap: () {
                  if (item.episodeSlug != null &&
                      item.episodeSlug!.isNotEmpty) {
                    final fixedEpSlug = normalizeAnimeSlug(item.episodeSlug!);
                    final uri = Uri(
                      path: '/episode/$fixedEpSlug',
                      queryParameters: {
                        'title': item.episodeTitle ?? 'Episode',
                        if (hasImage) 'animeImage': item.animeImage,
                      },
                    );
                    context.push(uri.toString());
                  } else {
                    context.go('/anime/${normalizeAnimeSlug(item.animeSlug)}');
                  }
                },
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: hasImage
                                  ? CachedNetworkImage(
                                      imageUrl: coverProxy(item.animeImage!),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: _repairingIds.contains(item.id)
                                            ? const CircularProgressIndicator()
                                            : const Icon(Icons.movie),
                                      ),
                                    ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(
                                value:
                                    (item.progress > 0 ? item.progress : 0.15)
                                        .clamp(0.0, 1.0),
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.animeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  // --- USER COMMENTS WIDGET (FIXED) ---
  Widget _buildUserCommentsWidget(String userId, AppUser? appUser) {
    return StreamBuilder<List<AnimeComment>>(
      stream: _commentService.getCommentsByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data ?? [];
        final cs = Theme.of(context).colorScheme;

        if (comments.isEmpty) return const Text('Belum ada komentar.');

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final comment = comments[idx];

            // ⚡ INDIKATOR PERLU REPAIR
            // Repair jika: Kosong, Sama dengan Slug, ATAU Mengandung "Episode" (indikasi judul episode, bukan anime)
            final bool needsRepair =
                comment.animeTitle.isEmpty ||
                comment.animeTitle == comment.animeSlug ||
                comment.animeTitle.contains('Episode');

            if (needsRepair) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _repairCommentTitle(comment);
              });
            }

            final displayTitle = (!needsRepair)
                ? comment.animeTitle
                : _formatSlugToTitle(comment.animeSlug);

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
                          child: Row(
                            children: [
                              if (_repairingCommentIds.contains(comment.id))
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: cs.primary),
                            const SizedBox(width: 4),
                            Text('${comment.rating}'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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

  void _showLogoutDialog(BuildContext context) {
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
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus History?'),
        content: const Text('Semua riwayat tontonan akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _watchHistoryService.clearWatchHistory(userId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}
