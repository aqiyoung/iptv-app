// Generate assets/data/channels_cn.json from iptv-org API.
//
// Usage:
//   dart run tools/build_channels.dart
//
// Reads:  https://iptv-org.github.io/api/channels.json
// Writes: assets/data/channels_cn.json
//
// iptv-org has 39,000+ channels. We filter to CN-region mainstream
// categories and rank by priority to keep under 500 channels.
import 'dart:convert';
import 'dart:io';

const String _endpoint = 'https://iptv-org.github.io/api/channels.json';
const String _outPath = 'assets/data/channels_cn.json';

const Set<String> _wantedCats = <String>{
  'general',
  'news',
  'sports',
  'music',
  'movies',
  'kids',
  'entertainment',
  'documentary',
  'education',
  'animation',
  'culture',
};

const Map<String, int> _catPriority = <String, int>{
  'news': 100,
  'general': 90,
  'entertainment': 80,
  'sports': 70,
  'movies': 60,
  'music': 50,
  'kids': 40,
  'documentary': 35,
  'education': 30,
  'animation': 25,
  'culture': 20,
};

final RegExp _chineseRe = RegExp(r'[\u4e00-\u9fff]');

int scoreChannel(Map<String, dynamic> c) {
  var s = 0;
  final cats = (c['categories'] as List? ?? const <String>[]).cast<String>();
  for (final cat in cats) {
    s += _catPriority[cat] ?? 0;
  }
  if (c['logo'] != null) s += 5;
  if (c['website'] != null) s += 2;
  if (_chineseRe.hasMatch(c['name'] as String? ?? '')) s += 10;
  return s;
}

bool isChinese(Map<String, dynamic> c) => c['country'] == 'CN';

Map<String, dynamic> toChannel(Map<String, dynamic> c) {
  return <String, dynamic>{
    'id': c['id'],
    'name': c['name'],
    'country': c['country'] ?? '',
    'categories': c['categories'] ?? const <String>[],
    'alt_names': c['alt_names'] ?? const <String>[],
    'website': c['website'],
    'logo': c['logo'],
    'is_nsfw': false,
  };
}

Future<void> main() async {
  stdout.writeln('Fetching $_endpoint ...');
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(_endpoint));
    final resp = await req.close();
    if (resp.statusCode != 200) {
      stderr.writeln('HTTP ${resp.statusCode}');
      exit(1);
    }
    final body = await resp.transform(utf8.decoder).join();
    final all = json.decode(body) as List;

    stdout.writeln('Total iptv-org channels: ${all.length}');

    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final c in all.cast<Map<String, dynamic>>()) {
      final id = c['id'] as String?;
      if (id == null || seen.contains(id)) continue;
      if (c['is_nsfw'] == true) continue;
      if (!isChinese(c)) continue;
      final cats =
          (c['categories'] as List? ?? const <String>[]).cast<String>();
      if (cats.isEmpty) continue;
      if (!cats.any(_wantedCats.contains)) continue;
      seen.add(id);
      final ch = toChannel(c);
      ch['_score'] = scoreChannel(c);
      out.add(ch);
    }

    out.sort(
      (a, b) => (b['_score'] as int).compareTo(a['_score'] as int),
    );
    final top = out
        .take(500)
        .map((m) => Map<String, dynamic>.from(m)..remove('_score'))
        .toList();
    top.sort((a, b) {
      final c = (a['country'] as String).compareTo(b['country'] as String);
      if (c != 0) return c;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    final encoded = json.encode(top);
    final file = File(_outPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(encoded);

    stdout.writeln(
      'Wrote ${top.length} channels, ${encoded.length} bytes '
      '(${(encoded.length / 1024).toStringAsFixed(1)} KB) -> $_outPath',
    );

    if (top.length > 500) {
      stderr.writeln('FAIL: ${top.length} > 500');
      exit(2);
    }
    if (encoded.length > 100 * 1024) {
      stderr.writeln('FAIL: ${encoded.length} bytes > 100KB');
      exit(2);
    }
    stdout.writeln('OK: under 500 channels and 100KB');
  } finally {
    client.close(force: true);
  }
}
