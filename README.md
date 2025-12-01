# Nonton Anime

Animo - Aplikasi Flutter untuk streaming anime

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

3. **Run app**
   ```bash
   flutter run
   ```


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
- ✅ Web


## 📚 Resources

- [Flutter Documentation](https://flutter.dev/)
- [Dart Language Tour](https://dart.dev/language)

## 📄 License

This project is licensed under the MIT License


---
## 🧑‍💻 Tim Kontributor

| NAMA | NIM |
| ------- | -------- |
| **[Ello Adrian Hariadi](https://github.com/Driannnn)** | 24111814024 |
| **[Muhammad Dwi Saputra](https://github.com/POKSI77)** | 24111814080 |
| **[Izora Elverda Narulita Putri](https://github.com/Elverda)** | 24111814012 |
| **[Hanna Maulidhea](https://github.com/maulidhea)** | 24111814091 |
| **[Najwa Chava Safiera](https://github.com/sh3vaya)** | 24111814118 |
| **[Muhammad Dzikri Azkia Ridwani](https://github.com/azzkiaa)** | 24111814076 |
| **[Muhammad Dzacky Maulana Yahya](https://github.com/LofeYN)** | 24111814127 |
| **[Eka Verarina](https://github.com/kaekka)** | 24111814004 |


---
**Last Updated:** October 31, 2025
