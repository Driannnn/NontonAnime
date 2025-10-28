import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';

import '../widgets/common.dart';
import '../models/anime_models.dart';
import 'anime_detail_page.dart';
import '../utils/slug_utils.dart';

class AnimeSearchPage extends StatefulWidget {
  const AnimeSearchPage({super.key});

  @override
  State<AnimeSearchPage> createState() => _AnimeSearchPageState();
}

class _AnimeSearchPageState extends State<AnimeSearchPage> {
  final _controller = TextEditingController();
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  bool _loading = false;
  String? _error;
  List<AnimeDisplay> _results = [];
  bool _hasSearched = false; // supaya "Belum ada hasil." nggak muncul sebelum cari apa2

  Future<void> _search(String keyword) async {
    final q = keyword.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _hasSearched = true;
    });

    try {
      final res = await _dio.get('/anime/search/$q');
      final data = res.data;

      List rawList = [];

      // 1. prioritas search_results (sesuai contoh kamu)
      if (data is Map && data['search_results'] is List) {
        rawList = data['search_results'];
      }
      // 2. fallback: data['data']
      else if (data is Map && data['data'] is List) {
        rawList = data['data'];
      }
      // 3. fallback: data langsung list
      else if (data is List) {
        rawList = data;
      }

      _results = rawList
          .whereType<Map>() // pastikan Map
          .map((e) => AnimeDisplay.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList();
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

  Widget _buildResultArea(BuildContext context) {
    // loading?
    if (_loading) {
      return const CenteredLoading();
    }

    // error?
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () => _search(_controller.text),
      );
    }

    // belum pernah cari apa-apa → tampilkan kosong tanpa message
    if (!_hasSearched) {
      return const SizedBox.shrink();
    }

    // sudah cari tapi kosong
    if (_results.isEmpty) {
      return const Center(
        child: Text('Tidak ditemukan.'),
      );
    }

    // ada hasil
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final item = _results[i];

        return InkWell(
          onTap: () {
  final rawSlug = item.slug;
  if (rawSlug == null || rawSlug.isEmpty) return;

  final fixedSlug = normalizeAnimeSlug(rawSlug);

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AnimeDetailPage(
        slug: fixedSlug,
        titleFallback: item.title,
      ),
    ),
  );
},

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // poster
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (c, _) => const ShimmerBox(),
                          errorWidget: (c, _, __) => const ImageFallback(),
                        )
                      : const ImageFallback(),
                ),
              ),
              const SizedBox(height: 4),
              // judul
              Text(
                item.title ?? '',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: const Text('Cari Anime'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ===== search field =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Cari anime...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // ===== tombol search =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Search'),
                onPressed: () => _search(_controller.text),
              ),
            ),
          ),

          // ===== hasil =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildResultArea(context),
            ),
          ),
        ],
      ),
    );
  }
}
