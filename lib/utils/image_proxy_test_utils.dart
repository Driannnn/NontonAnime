/// Testing utilities untuk image proxy
///
/// Gunakan untuk debug dan verify proxy functionality

import 'image_proxy_utils.dart';

/// Test proxy URL generation
void testProxyUrlGeneration() {
  final testUrls = [
    'https://www.sankavollerei.com/images/poster.jpg',
    'https://api.example.com/image.png',
    '/api/images/cover.webp',
    'images/anime/thumb.jpg',
  ];

  print('🧪 Testing Proxy URL Generation:\n');

  for (final url in testUrls) {
    final proxyUrl = getProxyImageUrl(url);
    final isProxy = isProxyUrl(proxyUrl);
    final extracted = extractOriginalUrl(proxyUrl);

    print('Original:  $url');
    print('Proxy:     $proxyUrl');
    print('Is Proxy:  $isProxy');
    print('Extracted: $extracted');
    print('---');
  }
}

/// Verify proxy server is reachable
Future<bool> verifyProxyServerHealth() async {
  try {
    // Di sini bisa test connection ke proxy server
    // Contoh: fetch ke http://localhost:3000
    print('✓ Proxy server verification placeholder');
    return true;
  } catch (e) {
    print('✗ Failed to verify proxy server: $e');
    return false;
  }
}
