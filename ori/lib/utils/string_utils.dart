String prettifyKey(String raw) {
  final replaced = raw.replaceAll('_', ' ').replaceAll('-', ' ');
  return replaced
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

