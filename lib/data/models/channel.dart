/// iptv-org 频道模型
import '../channel_name_zh.dart';

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

  /// UI 实际显示名称 — 优先中文 (alt_names 第一个含中文的),
  /// 兑底手工中文表 (channel_name_zh.dart), 最后原始 name.
  String get displayName {
    if (isChinese) {
      // 优先 alt_names 里第一个含中文的
      for (final a in altNames) {
        if (_hasChinese(a)) return a;
      }
    }
    // 兑底手工中文表
    final mapped = _manualZhMap[id] ?? _manualZhMap[name];
    if (mapped != null) return mapped;
    return name;
  }

  /// 中英对照的副标题 — 原名跟 displayName 不同时才返, 否则 null
  String? get displaySubtitle {
    final dn = displayName;
    if (dn == name) return null; // 已经是原名了
    // 中文名字 + 英文原名
    if (_hasChinese(dn) && !_hasChinese(name)) return name;
    return null;
  }

  static final RegExp _chineseRe = RegExp(r'[\u4e00-\u9fff]');
  static bool _hasChinese(String s) => _chineseRe.hasMatch(s);

  /// 手工中文映射表 — 兑底用, 避免循环引用.
  /// 实际定义在 lib/data/channel_name_zh.dart, 运行时通过 import 注入.
  static const Map<String, String> _manualZhMap = kChannelNameZh;

  factory Channel.fromJson(Map<String, dynamic> j) {
    // v0.3.5.1 (6/18): 支持 string 和 {url, type} dict 两种 source 格式.
    // channels_cn.json 现有 145 string 源 (iptv-org 原始格式) + 83 dict 源
    // (merge_known_sources.py 把 known_sources.json 合并后改的格式).
    // 之前 .cast<String>() 在 dict 上 view 不报错, 但访问时 TypeError 炸,
    // CCTV-5 加载不出来可能就是这原因.
    final rawSources = (j['sources'] as List?) ?? const [];
    final sources = <String>[];
    for (final s in rawSources) {
      if (s is String) {
        sources.add(s);
      } else if (s is Map) {
        final url = s['url'];
        if (url is String) sources.add(url);
      }
    }
    return Channel(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? (j['id'] as String),
      country: (j['country'] as String?) ?? '',
      categories:
          ((j['categories'] as List?)?.cast<String>()) ?? const <String>[],
      altNames: ((j['alt_names'] as List?)?.cast<String>()) ?? const <String>[],
      website: j['website'] as String?,
      logoUrl: j['logo'] as String?,
      sources: sources,
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
