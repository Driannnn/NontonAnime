import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../models/anime_models.dart';
import '../widgets/common.dart';
import '../utils/web_iframe.dart';

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
  String? _iframeViewType;
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
        .where(
          (e) => !e.isDownload && e.url != null && e.url!.trim().isNotEmpty,
        )
        .toList();
    if (playable.isNotEmpty) return playable.first;
    return null;
  }

  void _initWebViewFromUrl(String url) {
    debugPrint('🌐 _initWebViewFromUrl called, kIsWeb=$kIsWeb');
    if (kIsWeb) {
      // Web: gunakan WebIframeFactory
      debugPrint('🌐 Web platform detected, using WebIframeFactory');
      _iframeViewType = WebIframeFactory.register(url);
      setState(() {});
    } else {
      // Mobile: gunakan WebViewController
      debugPrint('📱 Mobile platform detected, using WebViewController');
      try {
        final ctrl = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(true)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                debugPrint('📱 WebView loading: $url');
              },
              onPageFinished: (String url) {
                debugPrint('📱 WebView finished: $url');
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('📱 WebView error: ${error.description}');
              },
            ),
          )
          ..loadRequest(Uri.parse(url));
        setState(() {
          _webCtrl = ctrl;
        });
      } catch (e) {
        debugPrint('📱 Error initializing WebViewController: $e');
      }
    }
  }

  // Check apakah URL adalah embed HTML (iframe, player dll) atau direct video
  bool _isEmbedUrl(String url) {
    if (url.isEmpty) return false;
    url = url.toLowerCase();

    // Jika URL adalah direct video file, jangan di WebView
    if (url.endsWith('.mp4') ||
        url.endsWith('.mkv') ||
        url.endsWith('.webm') ||
        url.endsWith('.avi') ||
        url.endsWith('.mov')) {
      return false; // Direct video = tidak bisa di WebView
    }

    // Semua URL lain dianggap embed content (player, iframe, etc)
    // atau minimal coba load di WebView dulu
    return true;
  }

  // Widget fallback ketika player tidak bisa load
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
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak bisa membuka URL')),
                      );
                    }
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

  // ganti episode (next/prev)
  void _loadNewEpisode(String slug, {String? newTitle}) {
    setState(() {
      _currentEpisodeSlug = slug;
      _webCtrl = null;
      _iframeViewType = null;
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
          final display = EpisodeDetailDisplay.fromMap(
            raw,
            widget.titleFallback,
          );

          // ambil stream utama sekarang
          final mainStream = _pickMainStream(display);

          // Check apakah URL bisa di-load di WebView
          final streamUrl = mainStream?.url?.trim();
          final canLoadInWebView =
              streamUrl != null &&
              streamUrl.isNotEmpty &&
              _isEmbedUrl(streamUrl);

          // DEBUG
          debugPrint('=== EPISODE PAGE DEBUG ===');
          debugPrint('kIsWeb: $kIsWeb');
          debugPrint('Stream URL: $streamUrl');
          debugPrint('Can load in WebView: $canLoadInWebView');
          debugPrint('_webCtrl: $_webCtrl');
          debugPrint('_iframeViewType: $_iframeViewType');

          // kalau bisa di-webview dan belum punya controller/iframe, init sekarang
          if (canLoadInWebView && _webCtrl == null && _iframeViewType == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_webCtrl == null && _iframeViewType == null) {
                debugPrint('Initializing WebView with URL: $streamUrl');
                _initWebViewFromUrl(streamUrl);
              }
            });
          }

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

              // ===== FALLBACK UNTUK WEB (jika tidak bisa load stream URL) =====
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Jika video tidak muncul, salin URL di atas dan buka di browser atau video player favorit Anda.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              // ===== JUDUL / INFO EPISODE =====
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
                          _loadNewEpisode(display.nextSlug!, newTitle: 'Next');
                        },
                        child: const Text('Next'),
                      ),
                  ],
                ),

              if (downloads.isEmpty && mainStream == null)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: ListTile(title: Text('Tidak ada sumber ditemukan.')),
                ),
            ],
          );
        },
      ),
    );
  }
}
