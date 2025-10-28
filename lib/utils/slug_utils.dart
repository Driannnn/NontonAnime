String normalizeAnimeSlug(String raw) {
  if (raw.isEmpty) return raw;

  // contoh input:
  // "https:/otakudesu.best/anime/digimon-bb-sub-indo"
  // "https://otakudesu.best/anime/sbdwk-s2-sub-indo/"
  // "digimon-bb-sub-indo"

  var s = raw.trim();

  // hilangkan trailing slash
  if (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }

  // kalau sudah tidak mengandung "http", kita anggap sudah slug normal
  if (!(s.startsWith('http://') || s.startsWith('https://') || s.startsWith('https:/'))) {
    return s;
  }

  // perbaiki "https:/foo" jadi "https://foo"
  if (s.startsWith('https:/') && !s.startsWith('https://')) {
    s = s.replaceFirst('https:/', 'https://');
  }
  if (s.startsWith('http:/') && !s.startsWith('http://')) {
    s = s.replaceFirst('http:/', 'http://');
  }

  // sekarang coba parse sebagai URL dan ambil segmen terakhir path
  try {
    final uri = Uri.parse(s);
    // cari segmen terakhir non-empty
    for (int i = uri.pathSegments.length - 1; i >= 0; i--) {
      final seg = uri.pathSegments[i];
      if (seg.isNotEmpty) {
        return seg;
      }
    }
  } catch (_) {
    // kalau gagal parse URI, fallback: ambil substring setelah "/anime/"
    final idx = s.indexOf('/anime/');
    if (idx != -1) {
      final part = s.substring(idx + '/anime/'.length);
      return part.replaceAll('/', '');
    }
  }

  return s;
}
