import '../models/channel.dart';

/// 国内常用频道筛选器
class IptvOrgFilter {
  const IptvOrgFilter();

  /// 中文 channel 筛选
  List<Channel> chineseChannels(List<Channel> all) {
    final out = <Channel>[];
    for (final c in all) {
      if (c.isNsfw) continue;
      if (!c.isChinese) continue;
      out.add(c);
    }
    return out;
  }

  /// 进一步筛选: 保留有主流 categories
  List<Channel> curated(List<Channel> all) {
    const wanted = <String>{
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
    final seen = <String>{};
    final out = <Channel>[];
    for (final c in chineseChannels(all)) {
      if (seen.contains(c.id)) continue;
      seen.add(c.id);
      if (c.categories.isEmpty) continue;
      if (!c.categories.any(wanted.contains)) continue;
      out.add(c);
    }
    return out;
  }
}
