import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common.dart';
import '../utils/slug_utils.dart';
import '../utils/image_proxy_utils.dart';

class CompletedAnimePage extends StatefulWidget {
  const CompletedAnimePage({super.key});

  @override
  State<CompletedAnimePage> createState() => _CompletedAnimePageState();
}

class _CompletedAnimePageState extends State<CompletedAnimePage> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  bool _loading = false;
  String? _error;

  // daftar anime tamat yang sudah diparse rapi
  List<_CompletedAnimeItem> _completedList = [];

  // pagination state
  int _currentPage = 1;
  int? _lastPage;
  bool _hasNext = false;
  bool _hasPrev = false;
  int? _nextPage;
  int? _prevPage;

  @override
  void initState() {
    super.initState();
    _fetchCompleted(page: 1);
  }

  Future<void> _fetchCompleted({required int page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _dio.get('/anime/complete-anime/$page');
      final body = res.data;

      if (body is! Map || body['data'] is! Map) {
        throw Exception(
          'Format /anime/complete-anime/$page tidak sesuai: $body',
        );
      }

      final inner = Map<String, dynamic>.from(body['data']);

      // ambil list anime tamat
      final rawList = inner['completeAnimeData'];
      final listAnime = (rawList is List) ? rawList : <dynamic>[];

      final parsedList = listAnime.whereType<Map>().map((m) {
        final mm = Map<String, dynamic>.from(m);

        return _CompletedAnimeItem(
          title: (mm['title'] ?? '').toString(),
          slug: (mm['slug'] ?? '').toString(),
          poster: (mm['poster'] ?? '').toString(),
          rating: (mm['rating'] ?? '').toString(),
          episodeCount: (mm['episode_count'] ?? '').toString(),
          lastRelease: (mm['last_release_date'] ?? '').toString(),
        );
      }).toList();

      _completedList = parsedList;

      // pagination
      final pag = inner['paginationData'];
      if (pag is Map) {
        final p = Map<String, dynamic>.from(pag);

        _currentPage = _asInt(p['current_page']) ?? page;
        _lastPage = _asInt(p['last_visible_page']);

        _hasNext = p['has_next_page'] == true;
        _hasPrev = p['has_previous_page'] == true;

        _nextPage =
            _asInt(p['next_page']) ?? (_hasNext ? _currentPage + 1 : null);
        _prevPage =
            _asInt(p['previous_page']) ?? (_hasPrev ? _currentPage - 1 : null);
      } else {
        _currentPage = page;
        _hasNext = false;
        _hasPrev = page > 1;
        _nextPage = _hasNext ? page + 1 : null;
        _prevPage = _hasPrev ? page - 1 : null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  void _goToPage(int? page) {
    if (page == null) return;
    _fetchCompleted(page: page);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.push('/home'),
        ),
        title: const Text('Anime Tamat'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ===== GRID LIST =====
          Expanded(
            child: _loading && _completedList.isEmpty
                ? const CenteredLoading()
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: ErrorView(
                          message:
                              'Gagal memuat anime tamat (page $_currentPage):\n$_error',
                          onRetry: () => _fetchCompleted(page: _currentPage),
                        ),
                      )
                    : _completedList.isEmpty
                        ? const Center(child: Text('Belum ada data anime tamat.'))
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              itemCount: _completedList.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.6,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemBuilder: (context, index) {
                                final item = _completedList[index];

                                final normalizedSlug =
                                    normalizeAnimeSlug(item.slug);

                                final ratingText = item.rating.trim();
                                final epText = item.episodeCount.trim();

                                return InkWell(
                                  onTap: () {
                                    if (normalizedSlug.isEmpty) return;
                                    context.push(
                                      '/anime/$normalizedSlug?source=completed',
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // poster
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: item.poster.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      coverProxy(item.poster),
                                                  fit: BoxFit.cover,
                                                  placeholder: (c, _) =>
                                                      const ShimmerBox(),
                                                  errorWidget: (c, _, __) =>
                                                      const ImageFallback(),
                                                )
                                              : const ImageFallback(),
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // judul
                                      Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // rating
                                      if (ratingText.isNotEmpty)
                                        Text(
                                          '⭐ $ratingText',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                      // jumlah episode
                                      if (epText.isNotEmpty)
                                        Text(
                                          '$epText eps',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                      // optional last release tanggal rilis terakhir
                                      if (item.lastRelease.trim().isNotEmpty)
                                        Text(
                                          item.lastRelease,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(color: cs.primary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),

          // ===== PAGINATION FOOTER =====
          Container(
            width: double.infinity,
            color: cs.surface.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // tombol prev
                FilledButton.tonal(
                  onPressed: _hasPrev
                      ? () => _goToPage(_prevPage ?? (_currentPage - 1))
                      : null,
                  child: const Text('Prev'),
                ),

                // info halaman di tengah
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page $_currentPage'
                      '${_lastPage != null ? " / $_lastPage" : ""}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_hasNext || _hasPrev)
                      Text(
                        _hasNext
                            ? 'Next → ${_nextPage ?? _currentPage + 1}'
                            : _hasPrev
                                ? '← Prev ${_prevPage ?? (_currentPage - 1)}'
                                : '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: cs.primary),
                      ),
                  ],
                ),

                // tombol next
                FilledButton(
                  onPressed: _hasNext
                      ? () => _goToPage(_nextPage ?? (_currentPage + 1))
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model kecil khusus halaman ini dengan Getter dan Setter Eksplisit
class _CompletedAnimeItem {
  // 1. Properti diubah menjadi private
  late String _title;
  late String _slug;
  late String _poster;
  late String _rating;
  late String _episodeCount;
  late String _lastRelease;

  // 2. Getter publik untuk setiap properti
  String get title => _title;
  String get slug => _slug;
  String get poster => _poster;
  String get rating => _rating;
  String get episodeCount => _episodeCount;
  String get lastRelease => _lastRelease;

  // 3. Setter publik untuk setiap properti
  set title(String value) => _title = value;
  set slug(String value) => _slug = value;
  set poster(String value) => _poster = value;
  set rating(String value) => _rating = value;
  set episodeCount(String value) => _episodeCount = value;
  set lastRelease(String value) => _lastRelease = value;

  // 4. Konstruktor diubah untuk menggunakan setter atau mengisi properti private
  _CompletedAnimeItem({
    required String title,
    required String slug,
    required String poster,
    required String rating,
    required String episodeCount,
    required String lastRelease,
  }) {
    // Menggunakan setter untuk mengisi nilai awal
    this.title = title;
    this.slug = slug;
    this.poster = poster;
    this.rating = rating;
    this.episodeCount = episodeCount;
    this.lastRelease = lastRelease;
  }
}
