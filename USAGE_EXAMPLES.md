# 📚 Image Proxy Usage Examples

Dokumentasi contoh penggunaan image proxy utilities.

## ⚠️ Penting

File ini adalah **dokumentasi**, bukan code yang bisa di-import.
Untuk implementasi yang sudah jadi, lihat:

- `lib/features/anime_card.dart` ✅
- `lib/features/anime_detail_page.dart` ✅

---

## 📌 Contoh 1: Penggunaan Dasar

Cara paling sederhana menggunakan proxy:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'utils/image_proxy_utils.dart';

CachedNetworkImage(
  imageUrl: getProxyImageUrl(imageUrl),  // ← Langsung pakai
  fit: BoxFit.cover,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
)
```

---

## 📌 Contoh 2: Dengan Null Safety

Handle case ketika URL kosong:

```dart
CachedNetworkImage(
  imageUrl: display.imageUrl != null
    ? getProxyImageUrl(display.imageUrl!)
    : 'https://via.placeholder.com/300x400',
  fit: BoxFit.cover,
)
```

---

## 📌 Contoh 3: Custom Widget

Reusable widget dengan proxy images:

```dart
class AnimeCardWithProxy extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final VoidCallback onTap;

  const AnimeCardWithProxy({
    this.imageUrl,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: getProxyImageUrl(imageUrl!),
                      fit: BoxFit.cover,
                      placeholder: (c, _) => _shimmerPlaceholder(),
                      errorWidget: (c, _, __) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      ),
    );
  }
}
```

---

## 📌 Contoh 4: Debug & Troubleshooting

Print proxy URL untuk debugging:

```dart
class DebugImageWidget extends StatelessWidget {
  final String imageUrl;

  const DebugImageWidget({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final proxyUrl = getProxyImageUrl(imageUrl);

    // Debug: Print ke console
    debugPrint('Original URL: $imageUrl');
    debugPrint('Proxy URL: $proxyUrl');
    debugPrint('Is Proxy: ${isProxyUrl(proxyUrl)}');

    return CachedNetworkImage(
      imageUrl: proxyUrl,
      fit: BoxFit.cover,
    );
  }
}
```

---

## 📌 Contoh 5: Enable/Disable Proxy

Conditional proxy berdasarkan configuration:

```dart
import 'config/environment.dart';

class ConditionalProxyImageWidget extends StatelessWidget {
  final String imageUrl;

  const ConditionalProxyImageWidget({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // Penggunaan proxy bisa di-disable via environment config
    final displayUrl = EnvironmentConfig.enableImageProxy
        ? getProxyImageUrl(imageUrl)
        : imageUrl;

    debugPrint(
      'Using ${EnvironmentConfig.enableImageProxy ? "proxy" : "direct"} URL',
    );

    return CachedNetworkImage(
      imageUrl: displayUrl,
      fit: BoxFit.cover,
    );
  }
}
```

---

## 📌 Contoh 6: Grid List dengan Proxy

Menampilkan list anime dalam grid dengan proxy images:

```dart
class AnimeGridList extends StatelessWidget {
  final List<Map<String, dynamic>> animes;

  const AnimeGridList({required this.animes});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
      ),
      itemCount: animes.length,
      itemBuilder: (context, index) {
        final anime = animes[index];
        return AnimeCardWithProxy(
          imageUrl: anime['imageUrl'] as String?,
          title: anime['title'] as String? ?? 'No Title',
          onTap: () {
            debugPrint('Tapped: ${anime['title']}');
            // Navigate to detail page
          },
        );
      },
    );
  }
}
```

---

## 📌 Contoh 7: Ekstrak URL dari Proxy

Mengubah proxy URL kembali ke URL original:

```dart
void exampleExtractUrl() {
  const originalUrl = 'https://www.sankavollerei.com/poster.jpg';
  final proxyUrl = getProxyImageUrl(originalUrl);

  debugPrint('Original: $originalUrl');
  debugPrint('Proxy: $proxyUrl');

  final extracted = extractOriginalUrl(proxyUrl);
  debugPrint('Extracted: $extracted');

  // Output:
  // Original: https://www.sankavollerei.com/poster.jpg
  // Proxy: http://localhost:3000/proxy?target=https%3A%2F%2F...
  // Extracted: https://www.sankavollerei.com/poster.jpg
}
```

---

## 🔧 Available Functions

### `getProxyImageUrl(String imageUrl) → String`

Mengubah image URL menjadi proxy URL.

**Input:** `https://www.sankavollerei.com/poster.jpg`
**Output:** `http://localhost:3000/proxy?target=https%3A%2F%2F...`

---

### `isProxyUrl(String url) → bool`

Check apakah URL sudah menggunakan proxy.

```dart
if (isProxyUrl(someUrl)) {
  print('Already using proxy');
}
```

---

### `extractOriginalUrl(String proxyUrl) → String?`

Extract original image URL dari proxy URL.

```dart
final original = extractOriginalUrl(proxyUrl);
// Returns: https://www.sankavollerei.com/poster.jpg
```

---

## ⚡ Quick Reference

### 1. Simple Use

```dart
imageUrl: getProxyImageUrl(display.imageUrl!),
```

### 2. With Null Safety

```dart
imageUrl: display.imageUrl != null
  ? getProxyImageUrl(display.imageUrl!)
  : 'https://via.placeholder.com/300x400',
```

### 3. Debug

```dart
debugPrint(getProxyImageUrl(url));
```

### 4. Check If Proxy

```dart
if (isProxyUrl(url)) { ... }
```

### 5. Extract Original

```dart
final original = extractOriginalUrl(proxyUrl);
```

### 6. Disable Proxy

```dart
// Di environment.dart:
static const bool enableImageProxy = false;
```

### 7. Change Proxy URL

```dart
// Di environment.dart proxyBaseUrl getter:
case Environment.development:
  return 'http://localhost:3000';
```

---

## 🎯 Best Practices

### ✅ DO

- Gunakan `getProxyImageUrl()` untuk semua image URLs
- Check null sebelum menggunakan URL
- Gunakan placeholder untuk loading state
- Provide error fallback widget
- Configure proxy URL di `environment.dart`

### ❌ DON'T

- Jangan hardcode proxy URL di widget
- Jangan mengabaikan error widget
- Jangan lupa import utilities
- Jangan disable proxy di production tanpa pertimbangan

---

## 🐛 Common Issues

### Issue: Gambar tidak muncul

```dart
// ❌ Salah
CachedNetworkImage(
  imageUrl: imageUrl,  // Langsung tanpa proxy
  ...
)

// ✅ Benar
CachedNetworkImage(
  imageUrl: getProxyImageUrl(imageUrl),  // Gunakan proxy
  ...
)
```

### Issue: Null exception

```dart
// ❌ Salah
CachedNetworkImage(
  imageUrl: getProxyImageUrl(imageUrl!),  // Bisa error jika null
  ...
)

// ✅ Benar
CachedNetworkImage(
  imageUrl: imageUrl != null
    ? getProxyImageUrl(imageUrl!)
    : 'fallback.jpg',
  ...
)
```

---

## 📁 Related Files

- **Implementation:** `lib/features/anime_card.dart` ✅
- **Implementation:** `lib/features/anime_detail_page.dart` ✅
- **Utils:** `lib/utils/image_proxy_utils.dart`
- **Config:** `lib/config/environment.dart`
- **Setup:** `IMAGE_PROXY_SETUP.md`

---

Untuk pertanyaan lebih lanjut, baca dokumentasi di `IMAGE_PROXY_SETUP.md` atau `IMPLEMENTATION_CHECKLIST.md`
