import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/api_client.dart';
import '../models/anime_models.dart';
import '../widgets/common.dart';
import 'episode_page.dart';
import '../utils/slug_utils.dart';
import '../utils/image_proxy_utils.dart';
import 'package:go_router/go_router.dart';

class AnimeDetailPage extends StatefulWidget {
  final String slug;
  final String? titleFallback;
  final String source;
  final String? genreSlug;
  final String? genreName;
  const AnimeDetailPage({
    super.key,
    required this.slug,
    this.titleFallback,
    this.source = 'home',
    this.genreSlug,
    this.genreName,
  });

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late Future<Map<String, dynamic>> _future;

  late String _normalizedSlug;

  @override
  void initState() {
    super.initState();
    _normalizedSlug = normalizeAnimeSlug(widget.slug);
    _future = fetchAnimeDetail(_normalizedSlug);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.source == 'search') {
              context.go('/search');
            } else if (widget.source == 'genre') {
              if (widget.genreSlug != null && widget.genreName != null) {
                context.go(
                  '/genre/${widget.genreSlug}?name=${widget.genreName}',
                );
              } else {
                context.go('/home');
              }
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Detail Anime'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const CenteredLoading();
          }
          if (snap.hasError) {
            return ErrorView(
              message: snap.error.toString(),
              onRetry: () =>
                  setState(() => _future = fetchAnimeDetail(_normalizedSlug)),
            );
          }

          final raw = snap.data!;
          final display = AnimeDetailDisplay.fromMap(raw, widget.titleFallback);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 120,
                      height: 170,
                      child: display.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: getProxyImageUrl(display.imageUrl!),
                              fit: BoxFit.cover,
                              placeholder: (c, _) => const ShimmerBox(),
                              errorWidget: (c, _, __) => const ImageFallback(),
                            )
                          : const ImageFallback(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          display.title ?? 'No Title',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (display.type != null)
                              pastelPill(context, display.type!),
                            if (display.status != null)
                              pastelPill(context, display.status!),
                            if (display.rating != null)
                              pastelPill(context, '⭐ ${display.rating}'),
                            if (display.episodesCount != null)
                              pastelPill(
                                context,
                                '${display.episodesCount} eps',
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ✅ GENRES di atas - bisa diklik
                        if (display.genres.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: display.genres.map((g) {
                              return ActionChip(
                                label: Text(g),
                                avatar: const Icon(Icons.local_offer, size: 16),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Genre: $g')),
                                  );
                                  // TODO: arahkan ke halaman filter / search genre jika diperlukan
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              if (display.synopsis != null)
                Text(
                  display.synopsis!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

              const SizedBox(height: 16),
              Divider(color: cs.primary.withOpacity(0.2)),
              const SizedBox(height: 8),

              // ✅ EPISODES di bawah
              Text('Episodes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (display.episodes.isEmpty) const Text('Belum ada episode.'),
              ...display.episodes.map((e) => _EpisodeTile(item: e)).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final EpisodeDisplay item;
  const _EpisodeTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(item.title ?? 'Episode'),
        subtitle: item.releasedAt != null ? Text(item.releasedAt!) : null,
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () {
          if (item.slug == null || item.slug!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Slug episode tidak ditemukan')),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EpisodePage(
                episodeSlug: item.slug!,
                titleFallback: item.title,
              ),
            ),
          );
        },
      ),
    );
  }
}
