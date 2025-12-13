import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';
import 'genre_results_page.dart';

class GenreListPage extends StatefulWidget {
  const GenreListPage({super.key});

  @override
  State<GenreListPage> createState() => _GenreListPageState();
}

class _GenreListPageState extends State<GenreListPage> {
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
      // Gunakan fetchGenreList() dari api_client dengan cf_clearance
      final genres = await fetchGenreList();
      
      _genres = genres
          .map((g) {
            final title = g['title']?.toString() ?? '';
            final genreId = g['genreId']?.toString() ?? '';
            return _GenreItem(name: title, slug: genreId);
          })
          .where((g) => g.slug.isNotEmpty)
          .toList();
      
      print('✅ Loaded ${_genres.length} genres');
    } catch (e) {
      print('❌ Error loading genres: $e');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
