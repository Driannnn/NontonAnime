import 'dart:async';
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
import '../utils/slug_utils.dart'; 

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
  
  // Variabel lokal untuk menyimpan gambar
  String? _currentAnimeImage;

  // Timer Progress
  Timer? _progressTimer;
  double _currentProgress = 0.05;

  final _authService = AuthService();
  final _watchHistoryService = WatchHistoryService();

  @override
  void initState() {
    super.initState();
    _currentEpisodeSlug = widget.episodeSlug;
    _currentAnimeImage = widget.animeImageUrl; 
    
    _future = fetchEpisodeDetail(_currentEpisodeSlug!);

    // ✅ FITUR PERBAIKAN: Cari gambar dengan logika slug yang lebih pintar
    _tryFixMissingImage();

    _startProgressTracking();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  /// 🛠️ Mencari gambar cover jika kosong
  Future<void> _tryFixMissingImage() async {
    // Jika gambar sudah ada dan valid, tidak perlu cari
    if (_currentAnimeImage != null && _currentAnimeImage!.isNotEmpty) return;

    try {
      debugPrint('🖼️ Mencari gambar untuk: $_currentEpisodeSlug');
      
      final cleanSlug = normalizeAnimeSlug(_currentEpisodeSlug!);
      
      // LOGIKA BARU: Gunakan split '-episode-' yang lebih aman daripada regex
      // Contoh: "utagoe-wa-mille-feuille-episode-1-sub-indo" -> "utagoe-wa-mille-feuille"
      String animeSlugCandidate = cleanSlug;
      if (cleanSlug.contains('-episode-')) {
        animeSlugCandidate = cleanSlug.split('-episode-')[0];
      }

      // Fetch detail anime
      final rawData = await fetchAnimeDetail(animeSlugCandidate);
      final animeDetail = AnimeDetailDisplay.fromMap(rawData, null);

      if (animeDetail.imageUrl != null && animeDetail.imageUrl!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentAnimeImage = animeDetail.imageUrl;
          });
          debugPrint('✅ Gambar ditemukan: $_currentAnimeImage');
          // Langsung simpan ke DB!
          _updateHistoryToDB();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Gagal auto-fix image: $e');
    }
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;

      setState(() {
        _currentProgress += 0.02;
        if (_currentProgress > 0.95) _currentProgress = 0.95;
      });

      _updateHistoryToDB();
    });
  }

  Future<void> _updateHistoryToDB({EpisodeDetailDisplay? display}) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Bersihkan slug untuk identifikasi anime
    final cleanSlug = normalizeAnimeSlug(widget.episodeSlug);
    final animeSlug = cleanSlug.contains('-episode-') 
        ? cleanSlug.split('-episode-').first 
        : cleanSlug;

    try {
      await _watchHistoryService.addWatchHistory(
        userId: currentUser.uid,
        animeSlug: animeSlug,
        animeTitle: widget.titleFallback ?? 'Unknown',
        // Pastikan menggunakan _currentAnimeImage yang mungkin sudah diperbaiki
        animeImage: _currentAnimeImage, 
        episodeSlug: _currentEpisodeSlug,
        episodeTitle: display?.title ?? widget.titleFallback,
        progress: _currentProgress,
      );
    } catch (_) {}
  }

  DirectStream? _pickMainStream(EpisodeDetailDisplay display) {
    final playable = display.directStreams
        .where((e) => !e.isDownload && e.url != null && e.url!.trim().isNotEmpty)
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
        debugPrint('📱 Error init WebView: $e');
      }
    }
  }

  bool _isEmbedUrl(String url) {
    if (url.isEmpty) return false;
    url = url.toLowerCase();
    if (url.endsWith('.mp4') || url.endsWith('.mkv')) return false;
    return true;
  }

  Widget _buildPlayerFallback(BuildContext context, String? streamUrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 48, color: Colors.white54),
          const SizedBox(height: 16),
          const Text('Player tidak bisa diload', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          if (streamUrl != null)
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse(streamUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      _currentProgress = 0.05;
      // Jangan reset _currentAnimeImage jika sudah ada
    });
    // Coba fix lagi (untuk jaga-jaga jika pindah ke anime beda, meski jarang)
    _tryFixMissingImage();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text(
          widget.titleFallback == null ? 'Episode' : 'Episode — ${widget.titleFallback}',
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
              onRetry: () => setState(() {
                _future = fetchEpisodeDetail(_currentEpisodeSlug!);
              }),
            );
          }

          final raw = snap.data!;
          final display = EpisodeDetailDisplay.fromMap(raw, widget.titleFallback);

          final mainStream = _pickMainStream(display);
          final streamUrl = mainStream?.url?.trim();
          final canLoadInWebView = streamUrl != null && streamUrl.isNotEmpty && _isEmbedUrl(streamUrl);

          if (canLoadInWebView && _webCtrl == null && _iframeViewType == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_webCtrl == null && _iframeViewType == null) {
                _initWebViewFromUrl(streamUrl);
              }
            });
          }

          // Trigger update history (termasuk simpan gambar) saat data episode siap
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateHistoryToDB(display: display);
          });

          final downloads = display.directStreams.where((e) => e.isDownload).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
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

              if (display.title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    display.title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

              // Navigasi Next/Prev
              if (display.nextSlug != null || display.prevSlug != null)
                Row(
                  children: [
                    if (display.prevSlug != null)
                      FilledButton.tonal(
                        onPressed: () => _loadNewEpisode(display.prevSlug!),
                        child: const Text('Previous'),
                      ),
                    const SizedBox(width: 12),
                    if (display.nextSlug != null)
                      FilledButton(
                        onPressed: () => _loadNewEpisode(display.nextSlug!),
                        child: const Text('Next'),
                      ),
                  ],
                ),

              const SizedBox(height: 24),
              
              // Download Links Section
              if (downloads.isNotEmpty) ...[
                Text(
                  'Download',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: downloads
                      .map((dl) => FilledButton.tonal(
                            onPressed: () async {
                              final uri = Uri.parse(dl.url ?? '');
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } catch (e) {
                                print('Error opening download URL: $e');
                              }
                            },
                            child: Text(dl.label ?? 'Download'),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],

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