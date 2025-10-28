import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerPage extends StatefulWidget {
  final String url;
  final String? title;
  const VideoPlayerPage({super.key, required this.url, this.title});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  WebViewController? _web;

  bool get _looksLikeDirectMedia {
    final u = widget.url.toLowerCase();
    return u.contains('.m3u8') ||
        u.endsWith('.mp4') ||
        u.contains('.mp4?') ||
        u.contains('playlist.m3u8') ||
        u.contains('manifest.m3u8');
  }

  @override
  void initState() {
    super.initState();
    if (_looksLikeDirectMedia) {
      _initVideo();
    } else {
      _initWebView();
    }
  }

  Future<void> _initVideo() async {
    _video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _video!.initialize();
    _chewie = ChewieController(
      videoPlayerController: _video!,
      autoInitialize: true,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true,
      materialProgressColors: ChewieProgressColors(),
    );
    if (mounted) setState(() {});
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..loadRequest(Uri.parse(widget.url));
    _web = controller;
    setState(() {});
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
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
            onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _looksLikeDirectMedia
            ? _buildVideo()
            : _buildWeb(),
      ),
    );
  }

  Widget _buildVideo() {
    if (_video == null || _chewie == null || !_video!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: _video!.value.aspectRatio == 0 ? 16 / 9 : _video!.value.aspectRatio,
      child: Chewie(controller: _chewie!),
    );
  }

  Widget _buildWeb() {
    if (_web == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: WebViewWidget(controller: _web!),
    );
  }
}
