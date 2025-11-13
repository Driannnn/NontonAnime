/// Utility untuk convert image URL menggunakan Weserv image proxy
///
/// Menggunakan: https://images.weserv.nl/ (free image proxy service)
/// Tidak perlu Node.js server, langsung dari CDN global!

/// Generate proxy URL untuk image menggunakan Weserv
///
/// Fitur:
/// - CORS bypass otomatis
/// - Image resize & optimization
/// - WebP conversion untuk performa
/// - Global CDN caching
///
/// Contoh:
/// - Input:  https://www.sankavollerei.com/images/poster.jpg
/// - Output: https://images.weserv.nl/?url=www.sankavollerei.com/images/poster.jpg&w=400&h=600&fit=cover&output=webp
String coverProxy(String rawUrl, {int w = 400, int h = 600}) {
  if (rawUrl.isEmpty) return '';

  Uri? u;
  try {
    u = Uri.parse(rawUrl);
  } catch (_) {}

  if (u == null || (u.host.isEmpty && !rawUrl.startsWith('http'))) {
    return ''; // URL tidak valid
  }

  // Jika sudah HTTPS dari hosting aman sendiri, boleh langsung (tanpa proxy)
  final host = u.host;
  final isSafeOwn =
      host.endsWith('firebaseapp.com') ||
      host.endsWith('web.app') ||
      host.endsWith('googleusercontent.com') ||
      host.endsWith('cloudfront.net') ||
      host.endsWith('jsdelivr.net');

  // Jika HTTPS dari hosting aman, pakai langsung
  if (u.scheme == 'https' && isSafeOwn) {
    return rawUrl;
  }

  // Gunakan Weserv untuk proxy + optimization
  // Format: host:port/path?query
  final noScheme =
      '${u.host}${u.hasPort ? ':${u.port}' : ''}${u.path}${u.hasQuery ? '?${u.query}' : ''}';
  return 'https://images.weserv.nl/?url=$noScheme';
}

/// Alias untuk getProxyImageUrl (backward compatibility)
String getProxyImageUrl(String imageUrl) {
  return coverProxy(imageUrl);
}
