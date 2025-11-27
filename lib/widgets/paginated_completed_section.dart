import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common.dart';
import '../utils/slug_utils.dart';
import '../utils/image_proxy_utils.dart';

// Model untuk item anime tamat
class _CompletedAnimeItem {
  late String _title;
  late String _slug;
  late String _poster;
  late String _rating;
  late String _episodeCount;
  late String _lastRelease;

  String get title => _title;
  String get slug => _slug;
  String get poster => _poster;
  String get rating => _rating;
  String get episodeCount => _episodeCount;
  String get lastRelease => _lastRelease;

  set title(String value) => _title = value;
  set slug(String value) => _slug = value;
  set poster(String value) => _poster = value;
  set rating(String value) => _rating = value;
  set episodeCount(String value) => _episodeCount = value;
  set lastRelease(String value) => _lastRelease = value;

  _CompletedAnimeItem({
    required String title,
    required String slug,
    required String poster,
    required String rating,
    required String episodeCount,
    required String lastRelease,
  }) {
    this.title = title;
    this.slug = slug;
    this.poster = poster;
    this.rating = rating;
    this.episodeCount = episodeCount;
    this.lastRelease = lastRelease;
  }
}

class PaginatedCompletedSection extends StatefulWidget {
  final String title;

  const PaginatedCompletedSection({required this.title, super.key});

  @override
  State<PaginatedCompletedSection> createState() =>
      _PaginatedCompletedSectionState();
}

class _PaginatedCompletedSectionState extends State<PaginatedCompletedSection> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  bool _loading = false;
  String? _error;

  List<_CompletedAnimeItem> _completedList = [];

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
    final textTheme = Theme.of(context).textTheme;

    if (_loading && _completedList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CenteredLoading(),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorView(
          message: 'Gagal memuat anime tamat (page $_currentPage):\n$_error',
          onRetry: () => _fetchCompleted(page: _currentPage),
        ),
      );
    }

    if (_completedList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Belum ada data anime tamat.')),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grid - Responsive dengan ukuran tile tetap
        LayoutBuilder(
          builder: (context, constraints) {
            // Tentukan jumlah kolom berdasarkan lebar layar
            final screenWidth = constraints.maxWidth;

            // Mobile: 3 kolom, Desktop: 3-6 kolom tergantung ukuran
            int crossAxisCount;
            if (screenWidth < 600) {
              crossAxisCount = 3; // Mobile
            } else if (screenWidth < 900) {
              crossAxisCount = 4; // Tablet
            } else {
              crossAxisCount = 5; // Desktop
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _completedList.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, index) {
                final item = _completedList[index];
                final normalizedSlug = normalizeAnimeSlug(item.slug);
                final ratingText = item.rating.trim();
                final epText = item.episodeCount.trim();

                return InkWell(
                  onTap: () {
                    if (normalizedSlug.isEmpty) return;
                    context.go('/anime/$normalizedSlug?source=completed');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item.poster.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: coverProxy(item.poster),
                                    fit: BoxFit.cover,
                                    placeholder: (c, _) => const ShimmerBox(),
                                    errorWidget: (c, _, __) =>
                                        const ImageFallback(),
                                  )
                                : const ImageFallback(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (ratingText.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '⭐ $ratingText',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (epText.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '$epText eps',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: cs.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),

        // Pagination Footer
        Container(
          width: double.infinity,
          color: cs.surface.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.tonal(
                onPressed: _hasPrev
                    ? () => _goToPage(_prevPage ?? (_currentPage - 1))
                    : null,
                child: const Text('Prev'),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page $_currentPage'
                    '${_lastPage != null ? " / $_lastPage" : ""}',
                    style: textTheme.bodySmall,
                  ),
                  if (_hasNext || _hasPrev)
                    Text(
                      _hasNext
                          ? 'Next → ${_nextPage ?? _currentPage + 1}'
                          : _hasPrev
                          ? '← Prev ${_prevPage ?? (_currentPage - 1)}'
                          : '',
                      style: textTheme.labelSmall?.copyWith(color: cs.primary),
                    ),
                ],
              ),
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
    );
  }
}
