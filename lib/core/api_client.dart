import 'dart:convert';
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'https://www.sankavollerei.com',
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  headers: {
    'Accept': 'application/json, text/plain, */*',
    'User-Agent': 'anime-pastel-app/1.0',
  },
));

Future<dynamic> getJson(String path) async {
  final resp = await dio.get(path);
  dynamic data = resp.data;
  if (data is String) {
    try { data = jsonDecode(data); } catch (_) {}
  }
  return data;
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
  final data = await getJson('/anime/home');

  if (data is List) {
    return {'Anime': data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()};
  }
  if (data is! Map) throw Exception('Format tak terduga dari server.');

  final map = Map<String, dynamic>.from(data);
  final result = <String, List<Map<String, dynamic>>>{};

  for (final e in map.entries) {
    final v = e.value;
    if (v is List) {
      result[e.key] = v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    } else if (v is Map && v.values.any((x) => x is List)) {
      for (final sub in v.entries) {
        if (sub.value is List) {
          result['${e.key}_${sub.key}'] = (sub.value as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    }
  }

  for (final key in ['data','result','home','animes','anime']) {
    final v = map[key];
    if (v is List && v.isNotEmpty) {
      result[key] = v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
  }

  if (result.isEmpty) {
    for (final v in map.values) {
      if (v is List && v.isNotEmpty && v.first is Map) {
        result['list'] = v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
    }
  }

  if (result.isEmpty) {
    throw Exception('Tidak ada daftar anime ditemukan dalam respons.');
  }
  return result;
}

/* =================== ANIME DETAIL =================== */
Future<Map<String, dynamic>> fetchAnimeDetail(String slug) async {
  final raw = await getJson('/anime/anime/$slug');
  final m = _unwrapMap(raw);
  return m;
}

/* =================== EPISODE DETAIL ================= */
Future<Map<String, dynamic>> fetchEpisodeDetail(String slug) async {
  final raw = await getJson('/anime/episode/$slug');
  final m = _unwrapMap(raw);
  return m;
}

/* ============== RESOLVE SERVER (optional) =========== */
Future<String?> resolveServerUrl(String serverId) async {
  try {
    final data = await getJson('/anime/server/$serverId');
    final m = _unwrapMap(data);
    for (final k in ['url','embed','streamUrl','src','link','file','playUrl']) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    if (m['data'] is Map) {
      final d2 = Map<String, dynamic>.from(m['data']);
      for (final k in ['url','embed','src','link']) {
        final v = d2[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
  } catch (_) {}
  return null;
}
