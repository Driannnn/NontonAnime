import 'dart:async'; // ✅ Tambahkan import ini untuk Timer
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/watch_history_service.dart';
import '../models/anime_models.dart';
import '../widgets/common.dart';
import '../utils/web_iframe.dart';
import '../widgets/comments_section.dart';

class EpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? titleFallback;
  final String? animeImageUrl;

  const EpisodePage({
    super.key,
    required this.episodeSlug,
    this.titleFallback,
    this.animeImageUrl,
  });

  @override
  State<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage> {
  late Future<Map<String, dynamic>> _future;

  WebViewController? _webCtrl;
  String? _iframeViewType;
  String? _currentEpisodeSlug;
  
  // ✅ Variabel untuk Timer Progress
  Timer? _progressTimer;
  double _currentProgress = 0.05; // Mulai dari 5%

  final _authService = AuthService();
  final _watchHistoryService = WatchHistoryService();

  @override
  void initState() {
    super.initState();
    _currentEpisodeSlug = widget.episodeSlug;
    _future = fetchEpisodeDetail(_currentEpisodeSlug!);
    
    // ✅ Mulai tracking waktu
    _startProgressTracking();
  }

  @override
  void dispose() {
    // ✅ Hentikan timer saat keluar halaman
    _progressTimer?.cancel();
    super.dispose();
  }

  // ✅ Logika Timer: Update progress setiap 30 detik
  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      
      // Asumsi 1 episode = 24 menit. 
      // 30 detik = ~2% progress (0.02)
      setState(() {
        _currentProgress += 0.02;
        if (_currentProgress > 0.95) _currentProgress = 0.95; // Mentok di 95%
      });

      // Simpan ke database (Silent update)
      _updateHistoryToDB();
    });
  }

  Future<void> _updateHistoryToDB({EpisodeDetailDisplay? display}) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _watchHistoryService.addWatchHistory(
        userId: currentUser.uid,
        animeSlug: widget.episodeSlug.split('/').first,
        animeTitle: widget.titleFallback ?? 'Unknown',
        animeImage: widget.animeImageUrl,
        episodeSlug: _currentEpisodeSlug,
        episodeTitle: display?.title ?? widget.titleFallback, // Pakai title yang ada
        progress: _currentProgress,
      );
    } catch (_) {}
  }

  // ... (Sisa kode WebView, Stream picker tetap sama, hanya sesuaikan build)

  DirectStream? _pickMainStream(EpisodeDetailDisplay display) {
    final playable = display.directStreams
        .where(
          (e) => !e.isDownload && e.url != null && e.url!.trim().isNotEmpty,
        )
        .toList();
    if (playable.isNotEmpty) return playable.first;
    return null;
  }

  void _initWebViewFromUrl(String url) {
    if (kIsWeb) {
      _iframeViewType = WebIframeFactory.register(url);
      setState(() {});
    } else {
      try {
        final ctrl = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(true)
          ..loadRequest(Uri.parse(url));
        setState(() {
          _webCtrl = ctrl;
        });
      } catch (e) {
        debugPrint('📱 Error initializing WebViewController: $e');
      }
    }
  }

  bool _isEmbedUrl(String url) {
    if (url.isEmpty) return false;
    url = url.toLowerCase();
    if (url.endsWith('.mp4') ||
        url.endsWith('.mkv') ||
        url.endsWith('.webm') ||
        url.endsWith('.avi') ||
        url.endsWith('.mov')) {
      return false;
    }
    return true;
  }
  
  Widget _buildPlayerFallback(BuildContext context, String? streamUrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 48, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Player tidak bisa diload',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (streamUrl != null)
            FilledButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.parse(streamUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Error launching URL: $e');
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka di Browser'),
            ),
        ],
      ),
    );
  }

  void _loadNewEpisode(String slug, {String? newTitle}) {
    setState(() {
      _currentEpisodeSlug = slug;
      _webCtrl = null;
      _iframeViewType = null;
      _future = fetchEpisodeDetail(slug);
      // Reset progress untuk episode baru
      _currentProgress = 0.05; 
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
          final display = EpisodeDetailDisplay.fromMap(
            raw,
            widget.titleFallback,
          );

          final mainStream = _pickMainStream(display);
          final streamUrl = mainStream?.url?.trim();
          final canLoadInWebView =
              streamUrl != null && streamUrl.isNotEmpty && _isEmbedUrl(streamUrl);

          if (canLoadInWebView && _webCtrl == null && _iframeViewType == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_webCtrl == null && _iframeViewType == null) {
                _initWebViewFromUrl(streamUrl);
              }
            });
          }

          // ✅ Panggil update history awal saat load berhasil
          // Menggunakan postFrameCallback agar tidak error saat build
          WidgetsBinding.instance.addPostFrameCallback((_) {
             _updateHistoryToDB(display: display);
          });

          final downloads = display.directStreams
              .where((e) => e.isDownload)
              .toList();

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
                  child: kIsWeb
                      ? (_iframeViewType == null
                          ? _buildPlayerFallback(context, streamUrl)
                          : HtmlElementView(viewType: _iframeViewType!))
                      : (_webCtrl == null
                          ? _buildPlayerFallback(context, streamUrl)
                          : WebViewWidget(controller: _webCtrl!)),
                ),
              ),
              const SizedBox(height: 16),

              // ===== FALLBACK UNTUK WEB =====
              if (_webCtrl == null && streamUrl != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📺 Stream URL:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          streamUrl,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (display.title != null && display.title!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    display.title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),

              // ===== DOWNLOAD LINKS =====
              if (downloads.isNotEmpty) ...[
                Text(
                  '⬇️ Download',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...downloads.map(
                  (d) => Card(
                    child: ListTile(
                      title: Text(d.label ?? 'Download'),
                      trailing: const Icon(Icons.download),
                      onTap: () async {
                        if (d.url != null && d.url!.isNotEmpty) {
                          try {
                            final uri = Uri.parse(d.url!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (_) {}
                        }
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
                          _loadNewEpisode(display.nextSlug!, newTitle: 'Next');
                        },
                        child: const Text('Next'),
                      ),
                  ],
                ),

              const SizedBox(height: 24),

              // ===== COMMENTS SECTION =====
              CommentsSection(
                animeSlug: _currentEpisodeSlug ?? widget.episodeSlug,
                animeTitleFallback: widget.titleFallback ?? 'Anime',
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}