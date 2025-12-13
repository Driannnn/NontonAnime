import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;

const String CF_CLEARANCE = 'A__SXdEj.VwjSc6OZDE_DXzWuJQ.QkWdD8dq_2HRkTI-1765557528-1.2.1.1-msM5u4ev42DFYszDIHj1z.ZJ5jlpttNmHuw2fGAuieYEqKt44FIA1k7mrwqbLAJCr1DpggvIpwqm.TsCFbFL.hmyeIG_Aznq4twQuXI.M2Er3jfangji7DpSwg6LMfnA66bzSurpmoRq4_45yahzqFlfsxr5YSE95Toz3SBMYbXlv72rHu2v5jXxbU7eczFkuj9kpJaAiw2SmM.7hj7bBSanBj0zzgT1JQ2MDumO8XU';

/// Adapter untuk menambahkan cf_clearance ke headers
HttpClientAdapter createAdapter() {
  final adapter = HttpClientAdapter();
  return adapter;
}

final dio = Dio(BaseOptions(
  baseUrl: 'https://www.sankavollerei.com/anime',
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  headers: {
    'Accept': 'application/json, text/plain, */*',
  },
))..interceptors.add(_CfClearanceInterceptor());

Future<dynamic> getJson(String path) async {
  try {
    final resp = await dio.get(path);
    dynamic data = resp.data;
    print('✓ API Response dari: $path');
    print('Status: ${resp.statusCode}');
    print('Data: $data');
    if (data is String) {
      try { data = jsonDecode(data); } catch (_) {}
    }
    return data;
  } on DioException catch (e) {
    print('✗ API Error: $path');
    print('Status: ${e.response?.statusCode}');
    print('Message: ${e.message}');
    print('Response: ${e.response?.data}');
    rethrow;
  }
}

/// Unwrap pola umum API: {"status":"success","data":{...}} atau {"result":{...}}, dll
Map<String, dynamic> _unwrapMap(dynamic data) {
  if (data is! Map) throw Exception('Format tidak terduga.');
  Map<String, dynamic> m = Map<String, dynamic>.from(data);
  // Kandidat container
  for (final key in ['data', 'result', 'anime', 'detail']) {
    final v = m[key];
    if (v is Map) return Map<String, dynamic>.from(v);
  }
  return m;
}

/* ======================= HOME ======================= */
Future<Map<String, List<Map<String, dynamic>>>> fetchHome() async {
  print('📡 Fetching home data...');
  final data = await getJson('/home');
  print('📦 Raw data dari server: $data');
  print('📦 Data type: ${data.runtimeType}');

  if (data is! Map) {
    print('❌ Data bukan Map, throw error');
    throw Exception('Format tak terduga dari server: ${data.runtimeType}');
  }

  final map = Map<String, dynamic>.from(data);
  final result = <String, List<Map<String, dynamic>>>{};

  // Cek apakah ada key 'data' yang berisi section (ongoing, completed, dll)
  final dataSection = map['data'];
  if (dataSection is Map) {
    print('🔍 Ditemukan data section dengan keys: ${dataSection.keys.toList()}');
    
    for (final sectionEntry in dataSection.entries) {
      final sectionName = sectionEntry.key;
      final sectionData = sectionEntry.value;
      
      if (sectionData is Map) {
        // Cari animeList di dalam section
        final animeList = sectionData['animeList'];
        if (animeList is List && animeList.isNotEmpty) {
          print('  ✓ Section "$sectionName" memiliki ${animeList.length} anime');
          result[sectionName] = animeList
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    }
  }

  if (result.isEmpty) {
    print('❌ Tidak ada data anime ditemukan');
    throw Exception('Tidak ada daftar anime ditemukan dalam respons.');
  }
  
  print('✅ Berhasil extract ${result.length} section');
  return result;
}

/* =================== GENRE LIST ================= */
Future<List<Map<String, dynamic>>> fetchGenreList() async {
  try {
    print('📡 Fetching genre list...');
    final data = await getJson('/genre');
    
    if (data is! Map) {
      throw Exception('Format tidak terduga dari /genre endpoint');
    }

    final map = Map<String, dynamic>.from(data);
    
    // Extract genreList dari response
    final dataSection = map['data'];
    if (dataSection is! Map) {
      throw Exception('data section is not a Map');
    }

    final genres = dataSection['genreList'];
    if (genres is! List) {
      throw Exception('genreList is not a List');
    }

    final parsedGenres = genres
        .whereType<Map>()
        .map((g) => Map<String, dynamic>.from(g))
        .toList();

    print('✅ Fetched ${parsedGenres.length} genres');
    return parsedGenres;
  } catch (e) {
    print('❌ Error fetching genres: $e');
    rethrow;
  }
}

/* =================== GENRE ANIME ================= */
/// Fetch anime list untuk satu genre dengan pagination
Future<Map<String, dynamic>> fetchGenreAnime({
  required String genreId,
  int page = 1,
}) async {
  try {
    print('📡 Fetching anime for genre: $genreId, page: $page');
    final res = await dio.get('/genre/$genreId', queryParameters: {'page': page});
    final body = res.data;
    
    if (body is! Map) {
      throw Exception('Format tidak terduga dari /genre/$genreId');
    }

    final map = Map<String, dynamic>.from(body);
    
    // Extract data section
    final dataSection = map['data'];
    if (dataSection is! Map) {
      throw Exception('data section is not a Map');
    }

    print('✅ Fetched genre anime data');
    return Map<String, dynamic>.from(dataSection);
  } catch (e) {
    print('❌ Error fetching genre anime: $e');
    rethrow;
  }
}

/* =================== ANIME DETAIL ================= */
Future<Map<String, dynamic>> fetchAnimeDetail(String slug) async {
  print('📡 Fetching anime detail: $slug');
  final data = await getJson('/anime/$slug');
  print('📦 Raw detail data: $data');
  
  if (data is! Map) {
    throw Exception('Format tidak terduga dari server.');
  }

  final map = Map<String, dynamic>.from(data);
  
  // API mengembalikan data langsung di dalam 'data' key
  final dataSection = map['data'];
  if (dataSection is Map) {
    print('✅ Extracted anime detail from data section');
    return Map<String, dynamic>.from(dataSection);
  }
  
  // Fallback jika struktur berbeda
  return map;
}

/* =================== SEARCH ANIME ================= */
/// Search anime berdasarkan keyword
Future<List<Map<String, dynamic>>> fetchSearchAnime(String keyword) async {
  try {
    print('📡 Searching anime: $keyword');
    final data = await getJson('/search/$keyword');
    
    if (data is! Map) {
      throw Exception('Format tidak terduga dari /search endpoint');
    }

    final map = Map<String, dynamic>.from(data);
    
    // Extract animeList dari response
    final dataSection = map['data'];
    if (dataSection is! Map) {
      throw Exception('data section is not a Map');
    }

    final animeList = dataSection['animeList'];
    if (animeList is! List) {
      throw Exception('animeList is not a List');
    }

    final results = animeList
        .whereType<Map>()
        .map((a) => Map<String, dynamic>.from(a))
        .toList();

    print('✅ Found ${results.length} anime matching "$keyword"');
    return results;
  } catch (e) {
    print('❌ Error searching anime: $e');
    rethrow;
  }
}

/* =================== EPISODE DETAIL ================= */
Future<Map<String, dynamic>> fetchEpisodeDetail(String slug) async {
  print('📡 Fetching episode detail: $slug');
  final data = await getJson('/episode/$slug');
  print('📦 Raw episode data: $data');
  
  if (data is! Map) {
    throw Exception('Format tidak terduga dari server.');
  }

  final map = Map<String, dynamic>.from(data);
  
  // API mengembalikan data langsung di dalam 'data' key
  final dataSection = map['data'];
  if (dataSection is Map) {
    print('✅ Extracted episode detail from data section');
    return Map<String, dynamic>.from(dataSection);
  }
  
  // Fallback jika struktur berbeda
  return map;
}

/* ============== HELPER: Extract Servers from Episode =========== */
/// Parse server data dari episode response
/// Returns: List<Map> dengan struktur {title, serverList}
List<Map<String, dynamic>> extractServerQualities(Map<String, dynamic> episodeData) {
  try {
    final serverData = episodeData['server'];
    if (serverData is! Map) return [];
    
    final qualities = serverData['qualities'];
    if (qualities is! List) return [];
    
    return qualities
        .whereType<Map>()
        .map((q) => Map<String, dynamic>.from(q))
        .toList();
  } catch (e) {
    print('❌ Error parsing server qualities: $e');
    return [];
  }
}

/* ============== HELPER: Extract Downloads from Episode =========== */
/// Parse download data dari episode response
/// Returns: List<Map> dengan struktur {title, size, urls}
List<Map<String, dynamic>> extractDownloadQualities(Map<String, dynamic> episodeData) {
  try {
    final downloadData = episodeData['downloadUrl'];
    if (downloadData is! Map) return [];
    
    final qualities = downloadData['qualities'];
    if (qualities is! List) return [];
    
    return qualities
        .whereType<Map>()
        .map((q) => Map<String, dynamic>.from(q))
        .toList();
  } catch (e) {
    print('❌ Error parsing download qualities: $e');
    return [];
  }
}

/* ============== HELPER: Extract Servers from Qualities =========== */
/// Extract server list dari satu quality tier
/// Returns: List<Map> dengan struktur {title, serverId, href}
List<Map<String, dynamic>> extractServersFromQuality(Map<String, dynamic> quality) {
  try {
    final serverList = quality['serverList'];
    if (serverList is! List) return [];
    
    return serverList
        .whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  } catch (e) {
    print('❌ Error parsing servers from quality: $e');
    return [];
  }
}

/* ============== HELPER: Extract Download URLs from Qualities =========== */
/// Extract download URLs dari satu quality tier
/// Returns: List<Map> dengan struktur {title, url}
List<Map<String, dynamic>> extractDownloadUrlsFromQuality(Map<String, dynamic> quality) {
  try {
    final urls = quality['urls'];
    if (urls is! List) return [];
    
    return urls
        .whereType<Map>()
        .map((u) => Map<String, dynamic>.from(u))
        .toList();
  } catch (e) {
    print('❌ Error parsing download URLs from quality: $e');
    return [];
  }
}

/* ============== RESOLVE SERVER (optional) =========== */
Future<String?> resolveServerUrl(String serverId) async {
  try {
    print('📡 Resolving server URL: $serverId');
    final data = await getJson('/server/$serverId');
    final m = _unwrapMap(data);
    
    // Try keys dalam urutan prioritas
    for (final k in ['url', 'embed', 'streamUrl', 'src', 'link', 'file', 'playUrl']) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) {
        print('✅ Found streaming URL from key "$k": ${v.trim().substring(0, 50)}...');
        return v.trim();
      }
    }
    
    // Fallback: cek di nested 'data' key
    if (m['data'] is Map) {
      final d2 = Map<String, dynamic>.from(m['data']);
      for (final k in ['url', 'embed', 'src', 'link']) {
        final v = d2[k];
        if (v is String && v.trim().isNotEmpty) {
          print('✅ Found streaming URL from nested data "$k": ${v.trim().substring(0, 50)}...');
          return v.trim();
        }
      }
    }
    
    print('⚠️ No streaming URL found in response');
    return null;
  } catch (e) {
    print('❌ Error resolving server: $e');
    return null;
  }
}

/* ============== GENERATE EMBED HTML =========== */
/// Generate HTML untuk embedding URL di WebView/iframe
/// Support berbagai tipe URL (embed, streaming, direct)
String generateEmbedHtml(String streamUrl) {
  final encodedUrl = Uri.encodeComponent(streamUrl);
  
  // HTML template dengan responsive design
  return '''
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Video Player</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            background-color: #000;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        
        .container {
            width: 100%;
            height: 100%;
            position: relative;
            background-color: #000;
        }
        
        iframe {
            width: 100%;
            height: 100%;
            border: none;
            display: block;
        }
        
        .error-container {
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            height: 100%;
            color: #fff;
            gap: 16px;
            padding: 24px;
            text-align: center;
        }
        
        .error-icon {
            font-size: 48px;
        }
        
        .error-text {
            font-size: 16px;
            opacity: 0.8;
        }
        
        .error-url {
            font-size: 12px;
            opacity: 0.6;
            word-break: break-all;
            max-width: 100%;
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
    
    <script>
        // Handle iframe errors
        document.querySelector('iframe').addEventListener('error', function() {
            document.body.innerHTML = `
                <div class="error-container">
                    <div class="error-icon">⚠️</div>
                    <div class="error-text">Video player tidak dapat dimuat</div>
                    <div class="error-url">URL: $streamUrl</div>
                </div>
            `;
        });
        
        // Prevent right-click pada video
        document.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            return false;
        });
    </script>
</body>
</html>
''';
}

/* ============== HELPER: Extract Download URLs (720p Only) =========== */
/// Extract download URLs hanya untuk 720p quality dari episode response
/// Returns: List<Map> dengan struktur {title, url, size, provider}
List<Map<String, dynamic>> extractDownloadUrls720p(Map<String, dynamic> episodeData) {
  try {
    final downloadData = episodeData['downloadUrl'];
    if (downloadData is! Map) return [];
    
    final qualities = downloadData['qualities'];
    if (qualities is! List) return [];
    
    final results = <Map<String, dynamic>>[];
    
    for (final quality in qualities) {
      if (quality is! Map) continue;
      
      final qualityTitle = quality['title']?.toString() ?? '';
      final size = quality['size']?.toString() ?? '';
      
      // Filter: Hanya 720p quality
      if (qualityTitle != '720p') continue;
      
      final urls = quality['urls'];
      if (urls is! List) continue;
      
      for (final u in urls) {
        if (u is! Map) continue;
        
        final provider = u['title']?.toString() ?? '';
        final url = u['url']?.toString();
        
        if (url != null && url.trim().isNotEmpty) {
          results.add({
            'title': '720p',
            'provider': provider,
            'size': size,
            'url': url.trim(),
          });
        }
      }
    }
    
    print('✅ Extracted ${results.length} download links (720p)');
    return results;
  } catch (e) {
    print('❌ Error parsing download URLs: $e');
    return [];
  }
}

/// Interceptor untuk menambahkan cf_clearance ke setiap request
class _CfClearanceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Tambahkan cf_clearance ke cookies untuk semua requests
    options.headers['Cookie'] = 'cf_clearance=$CF_CLEARANCE';
    print('📝 Request: ${options.path}');
    print('Cookie: cf_clearance=***');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✓ Response dari ${response.requestOptions.path}: ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('✗ Error pada ${err.requestOptions.path}: ${err.type}');
    handler.next(err);
  }
}
