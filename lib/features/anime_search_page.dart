import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/common.dart';
import '../models/anime_models.dart';
import 'anime_detail_page.dart';
import '../utils/slug_utils.dart';
import '../utils/image_proxy_utils.dart';

import '../cubits/anime_search_cubit.dart';
import '../cubits/anime_search_state.dart';

class AnimeSearchPage extends StatelessWidget {
  const AnimeSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => AnimeSearchCubit(),
      child: Scaffold(
        backgroundColor: cs.background,
        appBar: AppBar(title: const Text('Cari Anime'), centerTitle: true),
        body: const _SearchBody(),
      ),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final TextEditingController _controller = TextEditingController();

  void _doSearch(BuildContext context) {
    context.read<AnimeSearchCubit>().search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ===== search field =====
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _doSearch(context),
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
              onPressed: () => _doSearch(context),
            ),
          ),
        ),

        // ===== hasil =====
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<AnimeSearchCubit, AnimeSearchState>(
              builder: (context, state) {
                // loading?
                if (state.loading) {
                  return const CenteredLoading();
                }

                // error?
                if (state.error != null) {
                  return ErrorView(
                    message: state.error!,
                    onRetry: () => context.read<AnimeSearchCubit>().search(
                      _controller.text,
                    ),
                  );
                }

                // belum pernah cari (hasSearched == false)
                if (!state.hasSearched) {
                  return const SizedBox.shrink();
                }

                // sudah cari tapi kosong
                if (state.results.isEmpty) {
                  return const Center(child: Text('Tidak ditemukan.'));
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
                  itemCount: state.results.length,
                  itemBuilder: (context, i) {
                    final item = state.results[i];
                    return _SearchResultTile(item: item);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final AnimeDisplay item;
  const _SearchResultTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final rawSlug = item.slug;
        if (rawSlug == null || rawSlug.isEmpty) return;

        final fixedSlug = normalizeAnimeSlug(rawSlug);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AnimeDetailPage(slug: fixedSlug, titleFallback: item.title),
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
                      imageUrl: coverProxy(item.imageUrl!),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
