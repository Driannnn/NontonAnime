# 🖼️ Image Proxy Setup - Weserv (No Node.js Required!)

Gambar cover anime tidak muncul? Gunakan **Weserv image proxy** - solusi sederhana tanpa perlu menjalankan Node.js server!

## 📋 Persyaratan

- **Node.js** v14+ dan npm
- Proxy server sudah disiapkan di folder `anime-proxy/`

## 🚀 Setup & Jalankan Proxy Server

### 1. Buka folder proxy server

```bash
cd anime-proxy
```

### 2. Install dependencies

```bash
npm install
```

### 3. Jalankan proxy server

```bash
npm start
```

Proxy server akan berjalan di `http://localhost:3000`

**Output yang diharapkan:**

```
Proxy server running at http://localhost:3000
```

## 🔧 Cara Kerja

### Tanpa Proxy (Sebelum)

```
Flutter App → Direct Image URL → Server API
❌ Mungkin diblokir CORS
```

### Dengan Proxy (Sesudah)

```
Flutter App → Proxy URL → Proxy Server → Original Image URL → Server API
✅ CORS bypass, caching, lebih stabil
```

### Endpoint Proxy

```
GET http://localhost:3000/proxy?target={encodedImageUrl}
```

**Contoh:**

- Input: `https://www.sankavollerei.com/images/poster.jpg`
- Proxy URL: `http://localhost:3000/proxy?target=https%3A%2F%2Fwww.sankavollerei.com%2Fimages%2Fposter.jpg`

## 📝 Konfigurasi

File: `lib/config/environment.dart`

### Development (Localhost)

```dart
static const Environment _env = Environment.development;
// Proxy di: http://localhost:3000
```

### Production (Custom Domain)

```dart
static const Environment _env = Environment.production;
// Update proxyBaseUrl ke production URL Anda
```

### Disable Proxy

Jika ingin test tanpa proxy:

```dart
static const bool enableImageProxy = false;
```

## 🐛 Troubleshooting

### Masalah: "Failed to connect to proxy"

- ✅ Pastikan proxy server sudah running di terminal terpisah
- ✅ Cek port 3000 tidak terpakai aplikasi lain
- ✅ Di emulator, gunakan `http://10.0.2.2:3000` bukan `localhost:3000`

### Masalah: Gambar tetap tidak muncul

- ✅ Buka browser ke `http://localhost:3000/proxy?target=https%3A%2F%2Fwww.sankavollerei.com%2Fimages%2Fposter.jpg`
- ✅ Jika gambar muncul di browser, masalahnya di Flutter app
- ✅ Jika tidak muncul, masalahnya di proxy server

### Masalah: Port 3000 sudah terpakai

Gunakan port lain:

```bash
PORT=3001 npm start
```

Lalu update di `environment.dart`:

```dart
return 'http://localhost:3001';
```

## 📱 Emulator Android Tips

Emulator Android tidak bisa akses `localhost` langsung. Gunakan IP host:

```dart
// Di development.dart, ganti:
return 'http://10.0.2.2:3000'; // Android Emulator
// return 'http://localhost:3000'; // Web/iOS
```

## ✅ Verifikasi

Pastikan semua file sudah updated:

- ✅ `lib/utils/image_proxy_utils.dart` - Utility proxy
- ✅ `lib/config/environment.dart` - Configuration
- ✅ `lib/features/anime_card.dart` - Update ke proxy URL
- ✅ `lib/features/anime_detail_page.dart` - Update ke proxy URL

## 🎯 Next Steps

1. **Jalankan proxy server** di terminal
2. **Run Flutter app** - gambar seharusnya sekarang muncul
3. **Test di berbagai halaman** - list anime, detail anime
4. **Siap deploy** - untuk production, update `environment.dart` dengan production proxy URL

---

💡 **Pro Tips:**

- Proxy server melakukan caching image selama 1 jam (`Cache-Control: max-age=3600`)
- Gunakan `F12` di browser untuk debug image loading
- Check Flutter console untuk error messages
