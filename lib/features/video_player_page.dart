import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/web_iframe.dart'; // <= conditional import

class VideoPlayerPage extends StatefulWidget {
  final String url;
  final String? title;
  const VideoPlayerPage({super.key, required this.url, this.title});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  WebViewController? _webCtrl;
  String? _iframeViewType;

  bool get _looksLikeDirectMedia {
    final u = widget.url.toLowerCase();
    final isDirect =
        u.endsWith('.mp4') ||
        u.contains('.mp4?') ||
        u.endsWith('.m3u8') ||
        u.contains('playlist.m3u8') ||
        u.contains('manifest.m3u8');
    debugPrint('🎬 VideoPlayerPage: URL=$u, isDirect=$isDirect');
    return isDirect;
  }

  @override
  void initState() {
    super.initState();

    if (_looksLikeDirectMedia) {
      _initDirectVideo();
    } else {
      if (kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _iframeViewType = WebIframeFactory.register(widget.url);
          setState(() {});
        });
      } else {
        _initMobileWebView();
      }
    }
  }

  Future<void> _initDirectVideo() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _videoCtrl = controller;
    await controller.initialize();
    _chewieCtrl = ChewieController(
      videoPlayerController: controller,
      autoInitialize: true,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true,
      materialProgressColors: ChewieProgressColors(),
    );
    if (mounted) setState(() {});
  }

  void _initMobileWebView() {
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..loadRequest(Uri.parse(widget.url));
    _webCtrl = ctrl;
    setState(() {});
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text(widget.title ?? 'Player'),
        actions: [
          IconButton(
            tooltip: 'Buka di Browser',
            onPressed: () async {
              final uri = Uri.parse(widget.url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _looksLikeDirectMedia ? _buildDirectVideo() : _buildEmbed(),
      ),
    );
  }

  Widget _buildDirectVideo() {
    if (_videoCtrl == null ||
        _chewieCtrl == null ||
        !_videoCtrl!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final aspect = _videoCtrl!.value.aspectRatio == 0
        ? 16 / 9
        : _videoCtrl!.value.aspectRatio;

    return AspectRatio(
      aspectRatio: aspect,
      child: Chewie(controller: _chewieCtrl!),
    );
  }

  Widget _buildEmbed() {
    if (kIsWeb) {
      if (_iframeViewType == null) {
        debugPrint('🎬 _iframeViewType still null, loading...');
        return const Center(child: CircularProgressIndicator());
      }
      debugPrint(
        '🎬 _buildEmbed: showing iframe with viewType=$_iframeViewType',
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black,
          child: HtmlElementView(viewType: _iframeViewType!),
        ),
      );
    } else {
      if (_webCtrl == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _webCtrl!),
      );
    }
  }
}
