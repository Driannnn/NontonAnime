class AnimeDisplay {
  final String? title;
  final String? imageUrl;
  final String? slug;
  final String? badge;

  static const _kBase = 'https://www.sankavollerei.com';

  AnimeDisplay({this.title, this.imageUrl, this.slug, this.badge});

  static String? _norm(dynamic v) {
    if (v == null) return null;
    if (v is Map) {
      for (final k in ['url', 'link', 'image', 'src']) {
        final val = v[k];
        if (val is String && val.trim().isNotEmpty) {
          v = val;
          break;
        }
      }
      if (v is! String) return null;
    }
    if (v is! String) return null;
    var s = v.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('//'))
      s = 'https:$s';
    else if (s.startsWith('/'))
      s = '$_kBase$s';
    else if (!s.startsWith('http'))
      s = '$_kBase/$s';
    return s;
  }

  factory AnimeDisplay.fromMap(Map<String, dynamic> m) {
    String? getStr(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final title = getStr(['title', 'name', 'animeTitle', 'judul']);
    final slug = getStr(['slug', 'id', 'animeId', 'path']);
    final badge = getStr(['quality', 'type', 'episode', 'status']);

    final imgCandidates = <dynamic>[];
    for (final key in [
      'poster',
      'thumbnail',
      'thumb',
      'image',
      'img',
      'cover',
      'posterUrl',
      'poster_image',
    ]) {
      if (m[key] != null) imgCandidates.add(m[key]);
    }
    if (m['images'] is Map) {
      final images = m['images'] as Map;
      for (final fmt in ['jpg', 'webp', 'png']) {
        final variant = images[fmt];
        if (variant is Map && variant['large_image_url'] is String) {
          imgCandidates.add(variant['large_image_url']);
        }
      }
    }

    String? image;
    for (final cand in imgCandidates) {
      final normed = _norm(cand);
      if (normed != null) {
        image = normed;
        break;
      }
    }

    return AnimeDisplay(
      title: title,
      imageUrl: image,
      slug: slug,
      badge: badge,
    );
  }

  get rating => null;
}

/* ===================== DETAIL ===================== */
class AnimeDetailDisplay {
  final String? title;
  final String? imageUrl;
  final String? type;
  final String? status;
  final String? rating;
  final int? episodesCount;
  final String? synopsis;
  final List<String> genres;
  final List<EpisodeDisplay> episodes;

  static const _kBase = 'https://www.sankavollerei.com';

  AnimeDetailDisplay({
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.status,
    required this.rating,
    required this.episodesCount,
    required this.synopsis,
    required this.genres,
    required this.episodes,
  });

  static String? _normImg(dynamic v) {
    if (v == null) return null;
    if (v is Map) {
      for (final k in ['url', 'link', 'image', 'src']) {
        final val = v[k];
        if (val is String && val.trim().isNotEmpty) {
          v = val;
          break;
        }
      }
      if (v is! String) return null;
    }
    if (v is! String) return null;
    var s = v.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('//'))
      s = 'https:$s';
    else if (s.startsWith('/'))
      s = '$_kBase$s';
    else if (!s.startsWith('http'))
      s = '$_kBase/$s';
    return s;
  }

  /// Ambil episode dari berbagai struktur:
  /// - m['episodes'] / 'eps' / 'episode_list' / 'data'
  /// - atau scan semua list<Map> dan pilih yg punya kunci khas episode
  /// Ambil episode dari berbagai struktur dan hindari salah baca genres.
  /// Ambil episode dari berbagai struktur dan hindari salah baca genres.
  static List<EpisodeDisplay> _extractEpisodes(Map<String, dynamic> m) {
    List raw = [];

    // 1) Kandidat langsung bernuansa "ep"
    for (final k in [
      'episodes',
      'eps',
      'episode_list',
      'episodeList',
      'list_episodes',
      'daftar_episode',
      'episode_lists', // ✅ dari contoh payload kamu
    ]) {
      final v = m[k];
      if (v is List && v.isNotEmpty) {
        raw = v;
        break;
      }
    }

    // 2) Jika belum ketemu, cari di dalam 'data' / 'result' / 'detail' / 'anime'
    if (raw.isEmpty) {
      for (final containerKey in ['data', 'result', 'detail', 'anime']) {
        final container = m[containerKey];
        if (container is Map) {
          for (final k in container.keys) {
            final v = container[k];
            if (v is List &&
                v.isNotEmpty &&
                (k.toString().toLowerCase().contains('ep'))) {
              raw = v;
              break;
            }
          }
        }
        if (raw.isNotEmpty) break;
      }
    }

    // 3) Heuristik scan semua list<Map> yang "mirip episode"
    if (raw.isEmpty) {
      for (final e in m.entries) {
        final key = e.key.toString().toLowerCase();
        final v = e.value;

        if (key.contains('genre') || key.contains('tag')) continue;

        if (v is List && v.isNotEmpty && v.first is Map) {
          final first = Map<String, dynamic>.from(v.first as Map);

          final hasSlug = [
            'slug',
            'episodeId',
            'id',
            'path',
            'link',
          ].any((k) => first[k] is String && (first[k] as String).isNotEmpty);

          final hasEpHint = first.keys.any((kk) {
            final lk = kk.toString().toLowerCase();
            return lk.contains('ep') ||
                lk.contains('episode') ||
                lk.contains('number');
          });

          final parentLooksEp = key.contains('ep');

          if (hasSlug && (hasEpHint || parentLooksEp)) {
            raw = v;
            break;
          }
        }
      }
    }

    final out = <EpisodeDisplay>[];
    for (final it in raw) {
      if (it is Map) {
        out.add(EpisodeDisplay.fromMap(Map<String, dynamic>.from(it)));
      }
    }
    return out;
  }

  factory AnimeDetailDisplay.fromMap(
    Map<String, dynamic> mm,
    String? fallbackTitle,
  ) {
    // unwrap jika masih punya wadah 'data'/'result' dll (kadang model dipakai tanpa core unwrap)
    Map<String, dynamic> m = Map<String, dynamic>.from(mm);
    for (final key in ['data', 'result', 'anime', 'detail']) {
      final v = m[key];
      if (v is Map) {
        m = Map<String, dynamic>.from(v);
        break;
      }
    }

    String? getStr(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final title =
        getStr(['title', 'name', 'animeTitle', 'judul']) ?? fallbackTitle;

    final imgCandidates = <dynamic>[];
    for (final key in [
      'poster',
      'image',
      'img',
      'cover',
      'thumbnail',
      'thumb',
      'posterUrl',
      'poster_image',
    ]) {
      if (m[key] != null) imgCandidates.add(m[key]);
    }
    if (m['images'] is Map) {
      final images = m['images'] as Map;
      for (final fmt in ['jpg', 'webp', 'png']) {
        final variant = images[fmt];
        if (variant is Map && variant['large_image_url'] is String) {
          imgCandidates.add(variant['large_image_url']);
        }
      }
    }
    String? imageUrl;
    for (final cand in imgCandidates) {
      final s = _normImg(cand);
      if (s != null) {
        imageUrl = s;
        break;
      }
    }

    final type = getStr(['type', 'tipe', 'format']);

    // jangan salah baca "status: success" dari top-level
    String? status;
    final st = getStr(['status', 'state']);
    if (st != null && !['success', 'ok', 'true'].contains(st.toLowerCase())) {
      status = st;
    }

    final rating = getStr(['rating', 'score', 'rate']);
    
    // Parse synopsis dari berbagai format:
    // 1. String langsung: m['synopsis']
    // 2. Object dengan paragraphs: m['synopsis']['paragraphs'][]
    String? synopsis;
    final synopsisVal = m['synopsis'];
    if (synopsisVal is String) {
      synopsis = synopsisVal.trim();
    } else if (synopsisVal is Map) {
      // Handle synopsis.paragraphs array
      final paragraphs = synopsisVal['paragraphs'];
      if (paragraphs is List && paragraphs.isNotEmpty) {
        final paragraphTexts = paragraphs
            .whereType<String>()
            .where((p) => p.trim().isNotEmpty)
            .toList();
        if (paragraphTexts.isNotEmpty) {
          synopsis = paragraphTexts.join('\n\n');
          print('📝 Synopsis parsed dari ${paragraphTexts.length} paragraphs');
        }
      }
    }
    // Fallback ke deskripsi lain jika synopsis kosong
    if (synopsis == null || synopsis.isEmpty) {
      synopsis = getStr(['sinopsis', 'description', 'desc']);
    }

    final genres = <String>[];
    for (final k in ['genres', 'genre', 'tags']) {
      final v = m[k];
      if (v is List) {
        for (final it in v) {
          if (it is String) genres.add(it);
          if (it is Map) {
            for (final nk in ['name', 'title', 'label']) {
              final vv = it[nk];
              if (vv is String && vv.trim().isNotEmpty) {
                genres.add(vv.trim());
                break;
              }
            }
          }
        }
        if (genres.isNotEmpty) break;
      }
    }

    final episodes = _extractEpisodes(m);

    return AnimeDetailDisplay(
      title: title,
      imageUrl: imageUrl,
      type: type,
      status: status,
      rating: rating,
      episodesCount: episodes.isEmpty ? null : episodes.length,
      synopsis: synopsis,
      genres: genres,
      episodes: episodes,
    );
  }
}

/* ===================== EPISODE ===================== */
class EpisodeDisplay {
  final String? title;
  final String? slug;
  final String? releasedAt;

  EpisodeDisplay({this.title, this.slug, this.releasedAt});

  factory EpisodeDisplay.fromMap(Map<String, dynamic> m) {
    String? getStr(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    // Judul bisa datang sebagai 'episode' (contoh payload)
    String? title = getStr([
      'title',
      'name',
      'episodeTitle',
      'judul',
      'label',
      'episode',
    ]);

    // Kalau ada nomor episode, tambahkan ke judul (opsional tapi informatif)
    final numDyn = m['episode_number'];
    if (numDyn is num) {
      final n = numDyn.toInt();
      if ((title == null || !title.toLowerCase().contains('episode')) &&
          n > 0) {
        title = (title == null ? 'Episode $n' : '$title');
      }
    }

    final slug = getStr(['slug', 'id', 'episodeId', 'path', 'link']);
    final releasedAt = getStr([
      'released',
      'aired',
      'date',
      'published',
      'created_at',
      'uploaded_at',
    ]);

    return EpisodeDisplay(title: title, slug: slug, releasedAt: releasedAt);
  }
}

// =============== EPISODE DETAIL (baru) ===============
class EpisodeDetailDisplay {
  final String? title;

  /// URL yang bisa langsung diputar (stream_url / links / servers->url)
  final List<DirectStream> directStreams;

  /// Server yang harus di-resolve via /anime/server/:serverId (tetap dipertahankan)
  final List<ServerItem> servers;

  /// Navigasi next/prev
  final String? nextSlug;
  final String? prevSlug;

  EpisodeDetailDisplay({
    this.title,
    required this.directStreams,
    required this.servers,
    this.nextSlug,
    this.prevSlug,
  });

  factory EpisodeDetailDisplay.fromMap(
    Map<String, dynamic> mm,
    String? titleFallback,
  ) {
    // unwrap jika masih dibungkus
    Map<String, dynamic> m = Map<String, dynamic>.from(mm);
    for (final key in ['data', 'result', 'episode', 'detail']) {
      final v = m[key];
      if (v is Map) {
        m = Map<String, dynamic>.from(v);
        break;
      }
    }

    String? getStr(List<String> keys, [Map<String, dynamic>? src]) {
      final obj = src ?? m;
      for (final k in keys) {
        final v = obj[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final title =
        getStr(['title', 'name', 'episodeTitle', 'judul', 'episode']) ??
        titleFallback;

    final direct = <DirectStream>[];

    // 0) defaultStreamingUrl (API response terakhir)
    final defaultStreamUrl = getStr(['defaultStreamingUrl']);
    if (defaultStreamUrl != null) {
      direct.add(DirectStream(label: 'Default Stream', url: defaultStreamUrl));
    }

    // 1) stream_url (contoh payload)
    final streamUrl = getStr(['stream_url']);
    if (streamUrl != null) {
      direct.add(DirectStream(label: 'Stream', url: streamUrl));
    }

    // 2) pola umum lain yang mungkin ada
    for (final k in ['url', 'embed', 'streamUrl', 'playUrl']) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) {
        direct.add(DirectStream(label: k, url: v.trim()));
      }
    }
    for (final listKey in ['sources', 'links', 'streams', 'players']) {
      final v = m[listKey];
      if (v is List) {
        for (final it in v) {
          if (it is String && it.trim().isNotEmpty) {
            direct.add(DirectStream(label: listKey, url: it.trim()));
          } else if (it is Map) {
            String? url;
            for (final k in ['url', 'embed', 'src', 'file', 'link']) {
              final vv = it[k];
              if (vv is String && vv.trim().isNotEmpty) {
                url = vv.trim();
                break;
              }
            }
            final label =
                (it['name'] ??
                        it['label'] ??
                        it['server'] ??
                        it['quality'] ??
                        listKey)
                    ?.toString();
            if (url != null) direct.add(DirectStream(label: label, url: url));
          }
        }
      }
    }

    // 3) download_urls
    // Structure: { "downloadUrl": { "qualities": [ { "title": "360p", "size": "45.9 MB", "urls": [...] } ] } }
    // Filter: Hanya tampilkan 720p quality (dari semua provider)
    final dlData = m['downloadUrl'];
    print('🔍 Download data: $dlData');
    if (dlData is Map) {
      final qualities = dlData['qualities'];
      print('📊 Qualities: ${qualities?.length} items');
      if (qualities is List) {
        for (final quality in qualities) {
          if (quality is Map) {
            final qualityTitle = quality['title']?.toString() ?? '';
            final size = quality['size']?.toString() ?? '';
            final sizeStr = size.isNotEmpty ? ' — $size' : '';
            
            print('  ✓ Quality: $qualityTitle');
            
            // Filter: Hanya ambil "720p" quality
            if (qualityTitle != '720p') {
              print('    ⚠️ Skipped: Not 720p');
              continue;
            }
            
            final urls = quality['urls'];
            print('    📥 URLs: ${urls is List ? urls.length : 0} providers');
            
            if (urls is List) {
              for (final u in urls) {
                if (u is Map) {
                  final provider = u['title']?.toString() ?? '';
                  final url = u['url']?.toString();
                  
                  print('      - Provider: $provider');
                  
                  if (url != null && url.trim().isNotEmpty) {
                    final label = '720p$sizeStr — $provider';
                    print('        ✅ Added: $label');
                    direct.add(
                      DirectStream(
                        label: label,
                        url: url.trim(),
                        isDownload: true,
                      ),
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
    print('📥 Total download streams added: ${direct.where((d) => d.isDownload).length}');
    
    // Fallback: legacy download_urls structure
    final dl = m['download_urls'];
    if (dl is Map) {
      dl.forEach((formatKey, listVal) {
        final format = formatKey.toString().toUpperCase(); // MP4/MKV
        if (listVal is List) {
          for (final resObj in listVal) {
            if (resObj is Map) {
              final resolution = resObj['resolution']?.toString().toLowerCase();
              // hanya 720 / 1080
              if (resolution == null ||
                  !(resolution.contains('720') || resolution.contains('1080')))
                continue;
              final urls = resObj['urls'];
              if (urls is List) {
                for (final u in urls) {
                  if (u is Map) {
                    final provider = u['provider']?.toString();
                    final url = u['url']?.toString();
                    if (provider != null &&
                        provider.toLowerCase().contains('gofile') &&
                        url != null &&
                        url.trim().isNotEmpty) {
                      final label =
                          'Download $format ${resolution.toUpperCase()} — $provider';
                      direct.add(
                        DirectStream(
                          label: label,
                          url: url.trim(),
                          isDownload: true,
                        ),
                      );
                    }
                  }
                }
              }
            }
          }
        }
      });
    }

    // 4) servers (API structure: server.qualities[].serverList[])
    final servers = <ServerItem>[];
    
    // Structure: { "server": { "qualities": [ { "title": "360p", "serverList": [...] } ] } }
    final serverData = m['server'];
    if (serverData is Map) {
      final qualities = serverData['qualities'];
      if (qualities is List) {
        for (final quality in qualities) {
          if (quality is Map) {
            final qualityTitle = quality['title']?.toString() ?? '';
            final serverList = quality['serverList'];
            if (serverList is List) {
              for (final srv in serverList) {
                if (srv is Map) {
                  String? id;
                  for (final k in ['serverId', 'id', 'sid']) {
                    final vv = srv[k];
                    if (vv is String && vv.trim().isNotEmpty) {
                      id = vv.trim();
                      break;
                    }
                  }
                  final srvName = srv['title']?.toString() ?? 'Server';
                  final srvLabel = qualityTitle.isNotEmpty ? '$qualityTitle - $srvName' : srvName;
                  
                  if (id != null) {
                    servers.add(ServerItem(serverId: id, name: srvLabel));
                  }
                }
              }
            }
          }
        }
      }
    }
    
    // Fallback: legacy structure untuk kompatibilitas
    for (final listKey in ['servers', 'streamingServers']) {
      final v = m[listKey];
      if (v is List) {
        for (final it in v) {
          if (it is Map) {
            String? id;
            for (final k in ['serverId', 'id', 'sid']) {
              final vv = it[k];
              if (vv is String && vv.trim().isNotEmpty) {
                id = vv.trim();
                break;
              }
            }
            final name =
                (it['name'] ??
                        it['label'] ??
                        it['server'] ??
                        it['title'] ??
                        'Server')
                    .toString();
            String? url;
            for (final k in ['url', 'embed', 'src', 'file', 'link']) {
              final vv = it[k];
              if (vv is String && vv.trim().isNotEmpty) {
                url = vv.trim();
                break;
              }
            }
            if (url != null) {
              direct.add(
                DirectStream(label: name, url: url),
              ); // treat as direct
            } else if (id != null) {
              servers.add(ServerItem(serverId: id, name: name));
            }
          }
        }
      }
    }

    // 5) next / prev episode
    String? nextSlug, prevSlug;
    
    // New API structure
    if (m['nextEpisode'] is Map) {
      final next = Map<String, dynamic>.from(m['nextEpisode']);
      nextSlug = next['episodeId']?.toString();
    }
    if (m['prevEpisode'] is Map) {
      final prev = Map<String, dynamic>.from(m['prevEpisode']);
      prevSlug = prev['episodeId']?.toString();
    }
    
    // Fallback: legacy structure
    if (nextSlug == null && m['next_episode'] is Map) {
      nextSlug = getStr(['slug'], Map<String, dynamic>.from(m['next_episode']));
    }
    if (prevSlug == null && m['previous_episode'] is Map) {
      prevSlug = getStr(['slug'], Map<String, dynamic>.from(m['previous_episode']));
    }

    return EpisodeDetailDisplay(
      title: title,
      directStreams: direct,
      servers: servers,
      nextSlug: nextSlug,
      prevSlug: prevSlug,
    );
  }
}

class DirectStream {
  final String? label;
  final String? url;
  final bool isDownload; // ✅ tandai apakah ini link download

  DirectStream({this.label, this.url, this.isDownload = false});
}

class ServerItem {
  final String? serverId;
  final String? name;
  ServerItem({this.serverId, this.name});
}

/// Model untuk server dengan URL yang sudah di-resolve
class ResolvedServer extends ServerItem {
  final String? streamUrl;
  final bool isEmbedable;
  final String? embedHtml;
  
  ResolvedServer({
    required String? serverId,
    required String? name,
    this.streamUrl,
    this.isEmbedable = false,
    this.embedHtml,
  }) : super(serverId: serverId, name: name);
  
  /// Generate embed HTML untuk WebView
  String? generateEmbed() {
    if (streamUrl == null || streamUrl!.isEmpty) return null;
    if (!isEmbedable) return null;
    
    return '''
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Video Player</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            background-color: #000; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            height: 100vh; 
            font-family: system-ui, -apple-system, sans-serif;
        }
        .container { width: 100%; height: 100%; position: relative; }
        iframe { width: 100%; height: 100%; border: none; display: block; }
        .error { 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            flex-direction: column; 
            height: 100%; 
            color: #fff; 
            gap: 16px; 
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <iframe 
            src="$streamUrl"
            allowfullscreen
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            loading="lazy"
        ></iframe>
    </div>
</body>
</html>
''';
  }
}
