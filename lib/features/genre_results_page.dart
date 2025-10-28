import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/common.dart';
import '../models/anime_models.dart';
import 'anime_detail_page.dart';
import '../utils/slug_utils.dart';

class GenreAnimePage extends StatefulWidget {
  final String genreName;
  final String genreSlug;

  const GenreAnimePage({
    super.key,
    required this.genreName,
    required this.genreSlug,
  });

  @override
  State<GenreAnimePage> createState() => _GenreAnimePageState();
}

class _GenreAnimePageState extends State<GenreAnimePage> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  bool _loading = false;
  String? _error;

  List<AnimeDisplay> _animes = [];

  int _currentPage = 1;
  int? _lastPage;
  bool _hasNext = false;
  bool _hasPrev = false;
  int? _nextPage;
  int? _prevPage;

  @override
  void initState() {
    super.initState();
    _fetchByGenre(page: 1);
  }

  Future<void> _fetchByGenre({required int page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _dio.get(
        '/anime/genre/${widget.genreSlug}',
        queryParameters: {'page': page},
      );

      final data = res.data;
      if (data is! Map || data['data'] is! Map) {
        throw Exception('Format genre response tidak sesuai: $data');
      }

      final inner = Map<String, dynamic>.from(data['data']);

      // anime list
      final animeRaw = inner['anime'];
      final listAnime = (animeRaw is List) ? animeRaw : <dynamic>[];

      final parsedList = listAnime.whereType<Map>().map((m) {
        final map = Map<String, dynamic>.from(m);
        return AnimeDisplay.fromMap(map);
      }).toList();

      // pagination
      final pag = inner['pagination'];
      if (pag is Map) {
        final p = Map<String, dynamic>.from(pag);
        _currentPage = _tryInt(p['current_page']) ?? page;
        _lastPage = _tryInt(p['last_visible_page']);
        _hasNext = p['has_next_page'] == true;
        _hasPrev = p['has_previous_page'] == true;
        _nextPage = _tryInt(p['next_page']) ?? (_hasNext ? _currentPage + 1 : null);
        _prevPage = _tryInt(p['previous_page']) ?? (_hasPrev ? _currentPage - 1 : null);
      } else {
        _currentPage = page;
        _hasNext = false;
        _hasPrev = page > 1;
        _nextPage = _hasNext ? page + 1 : null;
        _prevPage = _hasPrev ? page - 1 : null;
      }

      _animes = parsedList;
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

  int? _tryInt(dynamic v) {
    if (v is int) return v;
    if (v is String) {
      return int.tryParse(v);
    }
    return null;
  }

  void _goToPage(int? page) {
    if (page == null) return;
    _fetchByGenre(page: page);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text(widget.genreName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // main content
          Expanded(
            child: _loading && _animes.isEmpty
                ? const CenteredLoading()
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: ErrorView(
                          message:
                              'Gagal memuat anime genre "${widget.genreName}" (slug "${widget.genreSlug}"):\n$_error',
                          onRetry: () => _fetchByGenre(page: _currentPage),
                        ),
                      )
                    : _animes.isEmpty
                        ? const Center(
                            child: Text('Belum ada anime untuk genre ini.'),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              itemCount: _animes.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.6,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemBuilder: (context, index) {
                                final item = _animes[index];
                                final normalizedSlug = item.slug == null
                                    ? null
                                    : normalizeAnimeSlug(item.slug!);

                                final ratingText =
                                    (item.rating ?? '').toString().trim();

                                return InkWell(
                                  onTap: () {
                                    if (normalizedSlug == null ||
                                        normalizedSlug.isEmpty) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AnimeDetailPage(
                                          slug: normalizedSlug,
                                          titleFallback: item.title,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: (item.imageUrl != null &&
                                                  item.imageUrl!.isNotEmpty)
                                              ? CachedNetworkImage(
                                                  imageUrl: item.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (c, _) =>
                                                      const ShimmerBox(),
                                                  errorWidget:
                                                      (c, _, __) =>
                                                          const ImageFallback(),
                                                )
                                              : const ImageFallback(),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.title ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (ratingText.isNotEmpty)
                                        Text(
                                          '⭐ $ratingText',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
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

          // pagination footer
          Container(
            width: double.infinity,
            color: cs.surface.withOpacity(0.6),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_hasNext || _hasPrev)
                      Text(
                        _hasNext
                            ? 'Next → ${_nextPage ?? _currentPage + 1}'
                            : _hasPrev
                                ? '← Prev ${_prevPage ?? (_currentPage - 1)}'
                                : '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.primary),
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
      ),
    );
  }
}
