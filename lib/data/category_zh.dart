/// IPTV 分类英文 → 中文映射
/// 播放页用, 防止 'sports'/'news' 等英文 enum 直接渲染
/// 实际 iptv_org_filter.dart 用的: news/sports/music/movies/kids
/// 这里写全一点, 防止以后扩展 (drama/anime/documentary 等)
const Map<String, String> kCategoryZh = {
  'sports': '体育',
  'news': '新闻',
  'movies': '电影',
  'music': '音乐',
  'kids': '少儿',
  'entertainment': '娱乐',
  'education': '教育',
  'documentary': '纪录',
  'general': '综合',
  'lifestyle': '生活',
  'anime': '动漫',
  'animation': '动漫',
  'auto': '汽车',
  'business': '财经',
  'classic': '经典',
  'comedy': '喜剧',
  'cooking': '美食',
  'culture': '文化',
  'drama': '剧场',
  'family': '家庭',
  'fantasy': '奇幻',
  'history': '历史',
  'horror': '恐怖',
  'legislative': '时政',
  'mystery': '悬疑',
  'religion': '宗教',
  'romance': '爱情',
  'science': '科学',
  'shop': '购物',
  'travel': '旅游',
  'weather': '天气',
  'xxx': '成人',
};

/// 把英文 category 翻成中文, 找不到/为空就原样返回
String categoryZh(String? en) {
  if (en == null || en.isEmpty) return '';
  return kCategoryZh[en.toLowerCase()] ?? en;
}
