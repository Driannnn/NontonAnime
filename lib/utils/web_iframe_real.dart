// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebIframeFactory {
  static int _counter = 0;

  static String? register(String url) {
    final viewType = 'iframe-${_counter++}';

    // Register iframe view factory dengan ui_web
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => _buildIframe(url),
    );

    return viewType;
  }

  static html.Element _buildIframe(String url) {
    final container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.margin = '0'
      ..style.padding = '0';

    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.margin = '0'
      ..style.padding = '0'
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen; payment'
      ..allowFullscreen = true;

    // Set sandbox attributes
    iframe.sandbox?.add('allow-same-origin');
    iframe.sandbox?.add('allow-scripts');
    iframe.sandbox?.add('allow-popups');
    iframe.sandbox?.add('allow-presentation');
    iframe.sandbox?.add('allow-forms');

    container.append(iframe);
    return container;
  }
}
