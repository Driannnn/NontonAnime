// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

class WebIframeFactory {
  static String? register(String url) {
    final viewType = 'iframe-${DateTime.now().microsecondsSinceEpoch}';

    // register view factory ke Flutter Web
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = '0'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture;'
        ..allowFullscreen = true
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });

    return viewType;
  }
}
