// class AnimeDetail {
//   final String title;
//   final String? japaneseTitle;
//   final String? poster;
//   final String? rating;
//   final String? produser;
//   final String? type;
//   final String? status;
//   final String? episodeCount;
//   final String? duration;
//   final String? releaseDate;
//   final String? studio;
//   final String? synopsis;
//   final List<AnimeGenre> genres;
//   final List<AnimeEpisode> episodes;
//   final List<AnimeRecommendation> recommendations;
//   final List<AnimeServer> servers; // optional (if API includes)
  
//   AnimeDetail({
//     required this.title,
//     this.japaneseTitle,
//     // this.poster,
//     this.rating,
//     this.produser,
//     this.type,
//     this.status,
//     this.episodeCount,
//     this.duration,
//     this.releaseDate,
//     this.studio,
//     this.synopsis,
//     required this.genres,
//     required this.episodes,
//     required this.recommendations,
//     required this.servers,
//   });

//   factory AnimeDetail.fromMap(Map<String, dynamic> map) {
//     return AnimeDetail(
//       title: map['title'] ?? '',
//       japaneseTitle: map['japanese_title'],
//       poster: map['poster'],
//       rating: map['rating'],
//       produser: map['produser'],
//       type: map['type'],
//       status: map['status'],
//       episodeCount: map['episode_count'],
//       duration: map['duration'],
//       releaseDate: map['release_date'],
//       studio: map['studio'],
//       synopsis: map['synopsis'],
//       genres: (map['genres'] as List?)
//               ?.map((e) => AnimeGenre.fromMap(e))
//               .toList() ??
//           [],
//       episodes: (map['episode_lists'] as List?)
//               ?.map((e) => AnimeEpisode.fromMap(e))
//               .toList() ??
//           [],
//       recommendations: (map['recommendations'] as List?)
//               ?.map((e) => AnimeRecommendation.fromMap(e))
//               .toList() ??
//           [],
//       servers: (map['servers'] as List?)
//               ?.map((e) => AnimeServer.fromMap(e))
//               .toList() ??
//           [],
//     );
//   }
// }

// class AnimeGenre {
//   final String name;
//   final String slug;

//   AnimeGenre({
//     required this.name,
//     required this.slug,
//   });

//   factory AnimeGenre.fromMap(Map<String, dynamic> map) {
//     return AnimeGenre(
//       name: map['name'] ?? '',
//       slug: map['slug'] ?? '',
//     );
//   }
// }

// class AnimeEpisode {
//   final String title;
//   final int number;
//   final String slug;
//   final List<AnimeServer> servers; // nanti bisa dipakai stream langsung

//   AnimeEpisode({
//     required this.title,
//     required this.number,
//     required this.slug,
//     required this.servers,
//   });

//   factory AnimeEpisode.fromMap(Map<String, dynamic> map) {
//     return AnimeEpisode(
//       title: map['episode'] ?? '',
//       number: map['episode_number'] is int
//           ? map['episode_number']
//           : int.tryParse(map['episode_number']?.toString() ?? '') ?? 0,
//       slug: map['slug'] ?? '',
//       servers: (map['servers'] as List?)
//               ?.map((e) => AnimeServer.fromMap(e))
//               .toList() ??
//           [],
//     );
//   }
// }

// class AnimeRecommendation {
//   final String title;
//   final String slug;
//   final String poster;

//   AnimeRecommendation({
//     required this.title,
//     required this.slug,
//     required this.poster,
//   });

//   factory AnimeRecommendation.fromMap(Map<String, dynamic> map) {
//     return AnimeRecommendation(
//       title: map['title'] ?? '',
//       slug: map['slug'] ?? '',
//       poster: map['poster'] ?? '',
//     );
//   }
// }

// class AnimeServer {
//   final String? id;
//   final String? name;

//   AnimeServer({this.id, this.name});

//   factory AnimeServer.fromMap(Map<String, dynamic> map) {
//     return AnimeServer(
//       id: map['serverId']?.toString(),
//       name: map['name']?.toString(),
//     );
//   }
// }
