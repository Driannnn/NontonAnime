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
  
  // Dio instance untuk fallback search
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  // Set untuk melacak item yang sedang diperbaiki agar tidak request berulang
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
              final base64String = profileImage.split(',')[1];
              final bytes = base64Decode(base64String);
              return CircleAvatar(
                  radius: 40, backgroundImage: MemoryImage(bytes));
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
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return "${word[0].toUpperCase()}${word.substring(1)}";
    }).join(' ');
  }

  /// Helper: Search Title Fallback
  Future<String?> _searchTitleBySlug(String keyword) async {
    try {
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
      // 1. Coba fetch detail episode dulu
      try {
         await fetchEpisodeDetail(item.episodeSlug ?? item.animeSlug);
      } catch (_) {}
      
      // 2. Fetch Anime Detail
      String slug = normalizeAnimeSlug(item.animeSlug);
      if (slug.contains('-episode-')) {
        slug = slug.split('-episode-')[0];
      }

      final rawData = await fetchAnimeDetail(slug);
      final detail = AnimeDetailDisplay.fromMap(rawData, null);

      if (detail.imageUrl != null && detail.imageUrl!.isNotEmpty) {
        await _watchHistoryService.updateImageDirectly(
            item.id, detail.imageUrl!);
      }
    } catch (e) {
      // ignore
    } finally {
      _repairingIds.remove(item.id);
    }
  }

  /// 🛠️ AUTO-REPAIR: Judul Komentar (VERSI PERBAIKAN)
  /// Menggunakan data Episode untuk mendapatkan judul asli, lalu dibersihkan.
  Future<void> _repairCommentTitle(AnimeComment comment) async {
    if (_repairingCommentIds.contains(comment.id)) return;
    _repairingCommentIds.add(comment.id);

    try {
      String foundTitle = '';

      // CARA 1: Fetch Detail EPISODE (Pasti Berhasil untuk slug singkatan)
      // Slug: "uwmf-episode-1..." -> API Episode kenal ini
      try {
        final rawData = await fetchEpisodeDetail(comment.animeSlug);
        final epDetail = EpisodeDetailDisplay.fromMap(rawData, null);
        
        // Hasil biasanya: "Utagoe wa Mille-Feuille Episode 1 Sub Indo"
        if (epDetail.title != null && epDetail.title!.isNotEmpty) {
           foundTitle = epDetail.title!;
        }
      } catch (_) {}

      // CARA 2: Jika Cara 1 Gagal, coba Fetch Anime Detail (Fallback)
      if (foundTitle.isEmpty) {
         try {
            String slug = normalizeAnimeSlug(comment.animeSlug);
            if (slug.contains('-episode-')) slug = slug.split('-episode-')[0];
            
            final rawData = await fetchAnimeDetail(slug);
            final animeDetail = AnimeDetailDisplay.fromMap(rawData, null);
            if (animeDetail.title != null) foundTitle = animeDetail.title!;
         } catch (_) {}
      }

      // CARA 3: Search (Ultimate Fallback)
      if (foundTitle.isEmpty) {
         String keyword = normalizeAnimeSlug(comment.animeSlug);
         if (keyword.contains('-episode-')) keyword = keyword.split('-episode-')[0];
         final res = await _searchTitleBySlug(keyword);
         if (res != null) foundTitle = res;
      }

      // PEMBERSIHAN JUDUL
      // Ubah "Utagoe wa Mille-Feuille Episode 1 Sub Indo" -> "Utagoe wa Mille-Feuille"
      if (foundTitle.isNotEmpty) {
         // Regex: Hapus kata 'Episode' (case insensitive) dan segala sesuatu setelahnya
         String cleanTitle = foundTitle.replaceAll(RegExp(r'\s+Episode\s+\d+.*', caseSensitive: false), '').trim();
         
         // Jika regex gagal (misal judul tidak ada kata 'Episode'), pakai judul aslinya saja
         if (cleanTitle.isEmpty) cleanTitle = foundTitle;

         // Simpan ke Database
         if (cleanTitle.isNotEmpty && cleanTitle.toLowerCase() != comment.animeTitle.toLowerCase()) {
            await _commentService.updateCommentTitleDirectly(comment.id, cleanTitle);
         }
      }

    } catch (e) {
      // ignore
    } finally {
      _repairingCommentIds.remove(comment.id);
    }
  }

  // --- BUILD UTAMA ---

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

          if (currentUser == null) {
            return _buildNotLoggedInView(cs);
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
                      child: const Text('Hapus History',
                          style: TextStyle(color: Colors.red)),
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

  // --- SUB-WIDGETS ---

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
                if (result == true && mounted) {
                  setState(() {});
                }
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
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

  Widget _buildWatchHistoryWidget(String userId) {
    return StreamBuilder<List<WatchHistory>>(
      stream: _watchHistoryService.getWatchHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var history = snapshot.data ?? [];
        final cs = Theme.of(context).colorScheme;

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
              'Anda belum menonton anime.',
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
              final hasImage =
                  item.animeImage != null && item.animeImage!.isNotEmpty;

              if (!hasImage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _repairMissingImage(item);
                });
              }

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
                    final fixedAnimeSlug = normalizeAnimeSlug(item.animeSlug);
                    context.go('/anime/$fixedAnimeSlug');
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
                                      placeholder: (c, url) =>
                                          const ShimmerBox(),
                                      errorWidget: (c, url, error) => Container(
                                        color: cs.surfaceContainerHighest,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : Container(
                                      color: cs.surfaceContainerHighest,
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _repairingIds.contains(item.id)
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : Icon(Icons.movie_filter,
                                                  color: cs.outline),
                                          const SizedBox(height: 4),
                                          Text(
                                            _repairingIds.contains(item.id)
                                                ? "Fixing..."
                                                : "No Image",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(Icons.play_arrow,
                                      color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                                child: LinearProgressIndicator(
                                  value: (item.progress > 0
                                          ? item.progress
                                          : 0.15)
                                      .clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey.withOpacity(0.5),
                                  color: Colors.redAccent,
                                  minHeight: 4,
                                ),
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
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (item.episodeTitle != null)
                        Text(
                          item.episodeTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: cs.primary,
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

  Widget _buildFavoritesWidget(String userId) {
    return StreamBuilder<List<Favorite>>(
      stream: _favoriteService.getFavorites(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final favorites = snapshot.data!;
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
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: coverProxy(item.animeImage ?? ''),
                            fit: BoxFit.cover,
                            placeholder: (c, url) => const ShimmerBox(),
                            errorWidget: (_, __, ___) => Container(
                              color: cs.surfaceContainerHighest,
                              child: const Icon(Icons.image),
                            ),
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

  // ✅ WIDGET KOMENTAR DENGAN AUTO-REPAIR JUDUL & FORMATTING
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

            // ⚡ INDIKATOR KOMENTAR PERLU DIPERBAIKI
            // Perlu repair jika judulnya kosong, sama dengan slug, ATAU mengandung kata "Episode" (berarti belum dipotong)
            final bool needsRepair = comment.animeTitle.isEmpty || 
                                     comment.animeTitle == comment.animeSlug ||
                                     comment.animeTitle.contains('Episode');

            // Trigger Auto-Repair Judul
            if (needsRepair) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _repairCommentTitle(comment);
              });
            }

            // TAMPILAN JUDUL:
            // 1. Judul DB (jika sudah diperbaiki dan tidak ada '-')
            // 2. Slug yang diformat (sementara)
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
                              // Indikator loading kecil jika sedang memperbaiki judul
                              if (_repairingCommentIds.contains(comment.id))
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                ),
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                ),
                              ),
                            ],
                          ),
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
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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
        content: const Text(
            'Semua riwayat tontonan akan dihapus dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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