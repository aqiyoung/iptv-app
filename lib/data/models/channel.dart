/// iptv-org 频道模型
class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.country,
    required this.categories,
    this.altNames = const <String>[],
    this.website,
    this.logoUrl,
    this.sources = const <String>[],
    this.isNsfw = false,
  });

  final String id;
  final String name;
  final String country;
  final List<String> categories;
  final List<String> altNames;
  final String? website;
  final String? logoUrl;
  final List<String> sources;
  final bool isNsfw;

  /// 主分类（取第一个）
  String get primaryCategory =>
      categories.isNotEmpty ? categories.first : 'general';

  /// 中文 channel 筛选
  bool get isChinese {
    if (country == 'CN' ||
        country == 'TW' ||
        country == 'HK' ||
        country == 'MO') {
      return true;
    }
    if (_hasChinese(name)) return true;
    for (final a in altNames) {
      if (_hasChinese(a)) return true;
    }
    return false;
  }

  static final RegExp _chineseRe = RegExp(r'[\u4e00-\u9fff]');
  static bool _hasChinese(String s) => _chineseRe.hasMatch(s);

  factory Channel.fromJson(Map<String, dynamic> j) {
    return Channel(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? (j['id'] as String),
      country: (j['country'] as String?) ?? '',
      categories:
          ((j['categories'] as List?)?.cast<String>()) ?? const <String>[],
      altNames: ((j['alt_names'] as List?)?.cast<String>()) ?? const <String>[],
      website: j['website'] as String?,
      logoUrl: j['logo'] as String?,
      sources: ((j['sources'] as List?)?.cast<String>()) ?? const <String>[],
      isNsfw: (j['is_nsfw'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'country': country,
        'categories': categories,
        'alt_names': altNames,
        'website': website,
        'logo': logoUrl,
        'sources': sources,
        'is_nsfw': isNsfw,
      };
}
