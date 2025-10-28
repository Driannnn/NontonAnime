import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Ambil HANYA AnimeDisplay dari models
import '../models/anime_models.dart' show AnimeDisplay;
// Ambil HANYA AnimeDetailPage dari file detail (hindari bentrok AnimeDisplay)
import './anime_detail_page.dart' show AnimeDetailPage;
import '../widgets/common.dart';

class AnimeCard extends StatelessWidget {
  final AnimeDisplay display;
  const AnimeCard({super.key, required this.display});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: () {
          final slug = display.slug;
          if (slug == null || slug.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Slug tidak ditemukan')),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnimeDetailPage(
                slug: slug,
                titleFallback: display.title,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: (display.imageUrl != null && display.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: display.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => const ShimmerBox(),
                      errorWidget: (c, _, __) => const ImageFallback(),
                    )
                  : const ImageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                display.title ?? 'No Title',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

