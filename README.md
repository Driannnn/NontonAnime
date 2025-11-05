# Nonton Anime

NontonAnime - Aplikasi Flutter untuk streaming anime online

## 🎯 Features

- Browse daftar anime
- Lihat detail anime dengan cover image
- Streaming episode anime
- Image proxy untuk bypass CORS
- Caching image untuk performa lebih baik

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.0+
- Dart 3.9.0+
- Node.js 14+ (untuk proxy server)

### Installation

1. **Clone repository**

   ```bash
   git clone https://github.com/Driannnn/NontonAnime.git
   cd diotest
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Setup proxy server** (di terminal terpisah)

   ```bash
   cd anime-proxy
   npm install
   npm start
   ```

   Proxy server akan berjalan di `http://localhost:3000`

4. **Run app**
   ```bash
   flutter run
   ```

## 📖 Image Proxy Documentation

Gambar cover tidak muncul? Lihat detail setup di [IMAGE_PROXY_SETUP.md](./IMAGE_PROXY_SETUP.md)

**Quick Start:**

1. Buka terminal baru
2. Jalankan proxy server: `cd anime-proxy && npm start`
3. Flutter app akan otomatis menggunakan proxy untuk load images

## 🏗️ Project Structure

```
lib/
├── main.dart              # Entry point
├── config/               # Configuration files
├── core/                 # Core functionality (API client)
├── features/             # UI pages (anime list, detail, episode)
├── models/              # Data models
├── cubits/              # State management
├── theme/               # Theme configuration
├── utils/               # Utilities (proxy, slug, etc)
└── widgets/             # Reusable widgets

anime-proxy/
├── server.js            # Express proxy server
└── package.json
```

## 🔑 Key Files

| File                                  | Purpose                               |
| ------------------------------------- | ------------------------------------- |
| `lib/utils/image_proxy_utils.dart`    | Image proxy utility functions         |
| `lib/config/environment.dart`         | Environment & proxy configuration     |
| `lib/features/anime_card.dart`        | Anime card widget dengan proxy images |
| `lib/features/anime_detail_page.dart` | Detail page dengan proxy images       |
| `anime-proxy/server.js`               | Express proxy server                  |

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🐛 Troubleshooting

### Gambar tidak muncul?

1. Pastikan proxy server running: `npm start` di folder `anime-proxy`
2. Cek port 3000 tidak terpakai
3. Lihat [IMAGE_PROXY_SETUP.md](./IMAGE_PROXY_SETUP.md) untuk detail

### Emulator Android?

Update di `lib/config/environment.dart`:

```dart
return 'http://10.0.2.2:3000'; // Ganti localhost
```

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/)
- [Dart Language Tour](https://dart.dev/language)
- [Express.js Documentation](https://expressjs.com/)

## 📄 License

This project is licensed under the MIT License

## 👨‍💻 Author

Driannnn

---

**Last Updated:** October 31, 2025
