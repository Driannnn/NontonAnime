/// Environment configuration untuk proxy dan API endpoints
///
/// Digunakan untuk membedakan antara development dan production builds

enum Environment { development, production }

class EnvironmentConfig {
  static const Environment _env = Environment.development;

  /// Base URL untuk image proxy server
  ///
  /// Development: localhost:3000 (untuk testing lokal)
  /// Production: sesuaikan dengan production proxy server
  static String get proxyBaseUrl {
    switch (_env) {
      case Environment.development:
        return 'http://localhost:3000';
      case Environment.production:
        // TODO: Ganti dengan production proxy URL
        return 'https://proxy.yourdomain.com';
    }
  }

  /// Enable/disable image proxy
  static const bool enableImageProxy = true;

  /// API base URL
  static const String apiBaseUrl = 'https://www.sankavollerei.com';
}
