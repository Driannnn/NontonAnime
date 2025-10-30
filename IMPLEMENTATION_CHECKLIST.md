## ✅ Image Proxy Implementation Checklist

Gambar cover anime tidak muncul? Berikut langkah-langkah untuk mengaktifkan image proxy:

### 📋 Files Yang Sudah Diupdate

- ✅ **lib/utils/image_proxy_utils.dart** - Utility untuk generate proxy URL
- ✅ **lib/config/environment.dart** - Configuration environment
- ✅ **lib/features/anime_card.dart** - Updated untuk gunakan proxy
- ✅ **lib/features/anime_detail_page.dart** - Updated untuk gunakan proxy
- ✅ **IMAGE_PROXY_SETUP.md** - Setup & troubleshooting guide
- ✅ **README.md** - Updated documentation

### 🚀 Langkah Implementasi

#### 1. **Setup Proxy Server** (Wajib dilakukan 1x)

```bash
# Terminal baru / Command Prompt baru
cd anime-proxy
npm install
npm start
```

Tunggu sampai muncul: `Proxy server running at http://localhost:3000`

#### 2. **Verifikasi File Code**

Pastikan file berikut sudah ter-update:

- [ ] `anime_card.dart` - import `image_proxy_utils.dart`
- [ ] `anime_card.dart` - gunakan `getProxyImageUrl(display.imageUrl!)`
- [ ] `anime_detail_page.dart` - import `image_proxy_utils.dart`
- [ ] `anime_detail_page.dart` - gunakan `getProxyImageUrl(display.imageUrl!)`

#### 3. **Run Flutter App**

```bash
flutter run
```

#### 4. **Test**

- [ ] Buka halaman list anime - gambar seharusnya muncul
- [ ] Buka detail anime - cover image seharusnya muncul
- [ ] Check Flutter console - tidak ada error tentang image

### 🔍 Verification Checklist

#### Console Output

```bash
# Terminal Proxy Server
✅ Proxy server running at http://localhost:3000

# Terminal Flutter
✅ Launching lib/main.dart on ... (tanpa error)
```

#### App Behavior

- [ ] Anime list cards menampilkan gambar
- [ ] Anime detail page menampilkan cover image
- [ ] Placeholder/shimmer muncul saat loading
- [ ] Image fallback muncul jika gagal (bukan blank)

### 🐛 Jika Masih Tidak Muncul?

**Step 1: Verify Proxy Server**

```bash
# Buka browser, masuk ke URL ini:
http://localhost:3000/proxy?target=https%3A%2F%2Fwww.sankavollerei.com%2Fimages%2Fposter.jpg

# Hasil:
✅ Gambar muncul di browser → Proxy OK, masalah di Flutter
❌ Error/blank → Proxy gagal, cek error message di terminal
```

**Step 2: Verify Flutter Code**

```bash
# Tambah debug print di anime_card.dart sebelum CachedNetworkImage:
print('Debug proxy URL: ${getProxyImageUrl(display.imageUrl!)}');

# Jalankan Flutter dan lihat console:
flutter run

# Cek output URL di console:
Debug proxy URL: http://localhost:3000/proxy?target=https%3A%2F%2F...
```

**Step 3: Check Network**

```bash
# Di Chrome DevTools (web) atau Logcat (Android):
- Lihat network requests ke localhost:3000
- Cek status 200 atau error
- Cek response header Content-Type
```

**Step 4: Port Issue**

```bash
# Jika port 3000 terpakai:
PORT=3001 npm start

# Update di lib/config/environment.dart:
return 'http://localhost:3001';
```

### 💡 Untuk Emulator Android

Update di `lib/config/environment.dart`:

```dart
static String get proxyBaseUrl {
  switch (_env) {
    case Environment.development:
      return 'http://10.0.2.2:3000'; // ← Ganti localhost ke 10.0.2.2
    case Environment.production:
      return 'https://proxy.yourdomain.com';
  }
}
```

### 📱 Untuk Build Production

1. Deploy proxy server ke production
2. Update `lib/config/environment.dart`:

```dart
static const Environment _env = Environment.production;

// Di production case:
case Environment.production:
  return 'https://proxy.yourdomain.com'; // ← Production URL
```

3. Build release:

```bash
flutter build apk --release
```

### 🎯 Konfigurasi Lanjutan

**Disable proxy jika ingin test tanpa proxy:**

```dart
// lib/config/environment.dart
static const bool enableImageProxy = false;
```

**Ganti image proxy URL secara global:**

- Edit di `lib/config/environment.dart`
- Cukup ubah di satu tempat, semua image otomatis pakai URL baru

### 📞 Support

Jika masih ada masalah:

1. Baca [IMAGE_PROXY_SETUP.md](./IMAGE_PROXY_SETUP.md)
2. Cek troubleshooting section di README.md
3. Verifikasi proxy server dengan membuka di browser
4. Check Flutter console untuk error messages

---

**💾 Save this checklist untuk referensi!**
