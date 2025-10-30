# 🖼️ Image Proxy dengan Weserv - SANGAT SEDERHANA!

**Gambar cover tidak muncul?** Tidak masalah, gunakan Weserv - **TANPA perlu Node.js server!**

## ✨ Apa itu Weserv?

Free image proxy service:

- ✅ Bypass CORS otomatis
- ✅ Optimize & resize image
- ✅ Convert ke WebP
- ✅ Global CDN
- ✅ **GRATIS dan LANGSUNG bisa dipakai!**

## 🚀 Setup (1 baris!)

```bash
flutter run
```

**DONE!** Gambar akan langsung muncul. Tidak perlu Node.js, tidak perlu server, tidak perlu apapun.

## 🔧 Cara Kerja

### File: `lib/utils/image_proxy_utils.dart`

```dart
String coverProxy(String rawUrl, {int w = 400, int h = 600}) {
  if (rawUrl.isEmpty) return '';
  Uri? u;
  try { u = Uri.parse(rawUrl); } catch (_) {}
  if (u == null || (u.host.isEmpty && !rawUrl.startsWith('http'))) {
    return '';
  }

  // Jika HTTPS dari hosting aman, pakai langsung
  final host = u.host;
  final isSafeOwn = host.endsWith('firebaseapp.com') ||
                    host.endsWith('web.app') ||
                    host.endsWith('cloudfront.net');

  if (u.scheme == 'https' && isSafeOwn) {
    return rawUrl;
  }

  // Gunakan Weserv proxy
  final noScheme = '${u.host}${u.hasPort ? ':${u.port}' : ''}${u.path}${u.hasQuery ? '?${u.query}' : ''}';
  return 'https://images.weserv.nl/?url=$noScheme&w=$w&h=$h&fit=cover&output=webp';
}

String getProxyImageUrl(String imageUrl) => coverProxy(imageUrl);
```

### Digunakan di Widget (anime_card.dart):

```dart
CachedNetworkImage(
  imageUrl: getProxyImageUrl(display.imageUrl!),  // ← just like this
  fit: BoxFit.cover,
  placeholder: (c, _) => const ShimmerBox(),
  errorWidget: (c, _, __) => const ImageFallback(),
)
```

## 📊 Flow

```
Flutter App
  ↓ imageUrl: https://www.sankavollerei.com/poster.jpg
  ↓ getProxyImageUrl()
  ↓ https://images.weserv.nl/?url=www.sankavollerei.com/poster.jpg&w=400&h=600...
  ↓ Weserv Global CDN ✅
  ↓ GAMBAR MUNCUL! 🎉
```

## ✅ Done!

- ✅ `lib/utils/image_proxy_utils.dart` - sudah dibuat
- ✅ `lib/features/anime_card.dart` - sudah pakai getProxyImageUrl()
- ✅ `lib/features/anime_detail_page.dart` - sudah pakai getProxyImageUrl()

**Cukup `flutter run`, gambar langsung muncul!**

## 🔍 Debug Jika Tetap Tidak Muncul

### Test 1: Buka URL di Browser

```
https://images.weserv.nl/?url=www.sankavollerei.com/poster.jpg&w=400&h=600&fit=cover&output=webp
```

- ✅ Gambar muncul? → Proxy OK
- ❌ Tidak muncul? → Image server error

### Test 2: Print Debug di Code

```dart
print('Image URL: ${display.imageUrl}');
print('Proxy URL: ${getProxyImageUrl(display.imageUrl ?? "")}');
```

## 💡 Customize Size

```dart
// Default
getProxyImageUrl(url)  // 400x600

// Custom
coverProxy(url, w: 300, h: 450)
```

**Selesai! Tidak perlu setup apapun lagi! 🎉**
