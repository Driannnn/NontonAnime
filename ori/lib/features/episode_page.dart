import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/api_client.dart';
import '../models/anime_models.dart';
import '../widgets/common.dart';

class EpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? titleFallback;
  const EpisodePage({super.key, required this.episodeSlug, this.titleFallback});

  @override
  State<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage> {
  late Future<Map<String, dynamic>> _future;

  WebViewController? _webCtrl;
  String? _currentEpisodeSlug;

  @override
  void initState() {
    super.initState();
    _currentEpisodeSlug = widget.episodeSlug;
    _future = fetchEpisodeDetail(_currentEpisodeSlug!);
  }

  // helper pilih stream playable (bukan download)
  DirectStream? _pickMainStream(EpisodeDetailDisplay display) {
    final playable = display.directStreams
        .where((e) => !e.isDownload && e.url != null && e.url!.trim().isNotEmpty)
        .toList();
    if (playable.isNotEmpty) return playable.first;
    return null;
  }

  void _initWebViewFromUrl(String url) {
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    setState(() {
        _webCtrl = ctrl;
    });
  }

  // ganti episode (next/prev)
  void _loadNewEpisode(String slug, {String? newTitle}) {
    setState(() {
      _currentEpisodeSlug = slug;
      _webCtrl = null;
      _future = fetchEpisodeDetail(slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text(
          widget.titleFallback == null
              ? 'Episode'
              : 'Episode — ${widget.titleFallback}',
          overflow: TextOverflow.ellipsis,
        ),
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
              onRetry: () {
                setState(() {
                  _future = fetchEpisodeDetail(_currentEpisodeSlug!);
                });
              },
            );
          }

          final raw = snap.data!;
          final display =
              EpisodeDetailDisplay.fromMap(raw, widget.titleFallback);

          // ambil stream utama sekarang
          final mainStream = _pickMainStream(display);

          // kalau kita belum punya webCtrl tapi sudah tahu URL stream,
          // schedule init setelah frame ini selesai, bukan langsung saat build.
          if (_webCtrl == null &&
              mainStream != null &&
              mainStream.url != null &&
              mainStream.url!.trim().isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              // double check lagi kalau _webCtrl masih null
              if (_webCtrl == null) {
                _initWebViewFromUrl(mainStream.url!.trim());
              }
            });
          }

          final downloads =
              display.directStreams.where((e) => e.isDownload).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // ===== PLAYER VIDEO DI ATAS =====
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _webCtrl == null
                      ? const Center(
                          child: Text(
                            'Loading player...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : WebViewWidget(controller: _webCtrl!),
                ),
              ),
              const SizedBox(height: 16),

              // ===== JUDUL / INFO EPISODE =====
              if (display.title != null &&
                  display.title!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    display.title!,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),

              // ===== DOWNLOAD LINKS =====
              if (downloads.isNotEmpty) ...[
                Text(
                  'Download',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...downloads.map(
                  (d) => Card(
                    child: ListTile(
                      title: Text(
                        d.label ?? 'Download',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.download),
                      onTap: () {
                        // kamu bisa pakai url_launcher di sini kalau mau buka link download
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Implement buka / unduh link di sini 👍',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ===== NAVIGASI NEXT / PREV =====
              if (display.nextSlug != null || display.prevSlug != null)
                Row(
                  children: [
                    if (display.prevSlug != null)
                      FilledButton.tonal(
                        onPressed: () {
                          _loadNewEpisode(
                            display.prevSlug!,
                            newTitle: 'Previous',
                          );
                        },
                        child: const Text('Previous'),
                      ),
                    const SizedBox(width: 12),
                    if (display.nextSlug != null)
                      FilledButton(
                        onPressed: () {
                          _loadNewEpisode(
                            display.nextSlug!,
                            newTitle: 'Next',
                          );
                        },
                        child: const Text('Next'),
                      ),
                  ],
                ),

              if (downloads.isEmpty && mainStream == null)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: ListTile(
                    title: Text('Tidak ada sumber ditemukan.'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
