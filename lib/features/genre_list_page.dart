import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common.dart';
import 'genre_results_page.dart';

class GenreListPage extends StatefulWidget {
  const GenreListPage({super.key});

  @override
  State<GenreListPage> createState() => _GenreListPageState();
}

class _GenreListPageState extends State<GenreListPage> {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://www.sankavollerei.com'));

  bool _loading = false;
  String? _error;
  List<_GenreItem> _genres = [];

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    setState(() {
      _loading = true;
      _error = null;
      _genres = [];
    });

    try {
      final res = await _dio.get('/anime/genre');
      final data = res.data;

      List raw = [];
      if (data is Map && data['data'] is List) {
        raw = data['data'];
      } else if (data is Map && data['genres'] is List) {
        raw = data['genres'];
      } else if (data is List) {
        raw = data;
      }

      _genres = raw
          .whereType<Map>()
          .map((m) {
            final map = Map<String, dynamic>.from(m);
            final name = map['name']?.toString() ?? map['genre']?.toString();
            // slug bisa `slug`, atau `path`, atau `url` terakhir
            String? slug = map['slug']?.toString();
            if (slug == null || slug.isEmpty) {
              // coba ekstrak dari url kalau ada
              final url =
                  map['otakudesu_url']?.toString() ?? map['url']?.toString();
              if (url != null) {
                slug = _extractLastSegment(url);
              }
            }
            return _GenreItem(name: name ?? '-', slug: slug ?? '');
          })
          .where((g) => g.slug.isNotEmpty)
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _extractLastSegment(String url) {
    var s = url.trim();
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    final idx = s.lastIndexOf('/');
    if (idx != -1 && idx < s.length - 1) {
      return s.substring(idx + 1);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(title: const Text('Genre'), centerTitle: true),
      body: _loading
          ? const CenteredLoading()
          : _error != null
          ? ErrorView(message: _error!, onRetry: _fetchGenres)
          : _genres.isEmpty
          ? const Center(child: Text('Tidak ada genre.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _genres.map((g) {
                      return InkWell(
                        onTap: () {
                          // Navigate to genre results
                          context.go(
                            '/genre/${g.slug}?name=${Uri.encodeComponent(g.name)}',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cs.secondary.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            g.name,
                            style: TextStyle(
                              color: cs.onBackground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GenreItem {
  final String name;
  final String slug;
  _GenreItem({required this.name, required this.slug});
}
