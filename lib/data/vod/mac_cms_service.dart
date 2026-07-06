/// MacCMS API 客户端
///
/// 直接调用 TVBox type=1 站点提供的 MacCMS 格式 API
/// API 格式: api.php/provide/vod?ac=list&t=xxx&pg=xx

import 'dart:convert';
import 'package:http/http.dart' as http;

/// 视频条目
class VODItem {
  final String vodId;
  final String name;
  final String pic;
  final String remarks;
  final String area;
  final String year;
  final String content;
  final String playFrom;
  final String playUrl;

  const VODItem({
    this.vodId = '',
    this.name = '',
    this.pic = '',
    this.remarks = '',
    this.area = '',
    this.year = '',
    this.content = '',
    this.playFrom = '',
    this.playUrl = '',
  });

  factory VODItem.fromJson(Map<String, dynamic> json) {
    return VODItem(
      vodId: json['vod_id']?.toString() ?? '',
      name: json['vod_name'] as String? ?? '',
      pic: json['vod_pic'] as String? ?? '',
      remarks: json['vod_remarks'] as String? ?? '',
      area: json['vod_area'] as String? ?? '',
      year: json['vod_year'] as String? ?? '',
      content: json['vod_content'] as String? ?? '',
      playFrom: json['vod_play_from'] as String? ?? '',
      playUrl: json['vod_play_url'] as String? ?? '',
    );
  }

  /// 获取第一个播放地址
  String? get firstPlayUrl {
    if (playUrl.isEmpty) return null;
    // 格式: 集名$url#集名$url
    final parts = playUrl.split('#');
    if (parts.isEmpty) return null;
    final first = parts.first.split('\$');
    return first.length > 1 ? first[1].trim() : null;
  }

  /// 解析所有剧集
  List<PlayEpisode> get episodes {
    if (playUrl.isEmpty) return [];
    return playUrl.split('#').map((part) {
      final segs = part.split('\$');
      return PlayEpisode(
        name: segs.length > 1 ? segs[0].trim() : '播放',
        url: segs.length > 1 ? segs[1].trim() : '',
      );
    }).where((e) => e.url.isNotEmpty).toList();
  }
}

class PlayEpisode {
  final String name;
  final String url;

  const PlayEpisode({required this.name, required this.url});

  /// 是否为 m3u8 流
  bool get isM3U8 => url.contains('.m3u8') || url.contains('m3u8');
}

/// 分类结果
class CategoryResult {
  final List<VODItem> list;
  final int page;
  final int pageCount;
  final int total;

  const CategoryResult({
    this.list = const [],
    this.page = 1,
    this.pageCount = 0,
    this.total = 0,
  });

  factory CategoryResult.fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List<dynamic>?)
            ?.map((item) => VODItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
    return CategoryResult(
      list: list,
      page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
      pageCount: int.tryParse(json['pagecount']?.toString() ?? '') ?? 0,
      total: int.tryParse(json['total']?.toString() ?? '') ?? list.length,
    );
  }
}

/// MacCMS API 客户端
class MacCMSService {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  MacCMSService(this.baseUrl, {http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();

  void dispose() => _client.close();

  Uri _buildUri(Map<String, String> params) {
    final url = baseUrl.replaceAllMapped(RegExp(r'/?$'), (m) => '');
    return Uri.parse('$url/').replace(queryParameters: params);
  }

  Map<String, String> get _headers => {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': baseUrl,
      };

  Future<Map<String, dynamic>> _get(Map<String, String> params) async {
    final uri = _buildUri(params);
    final response = await _client.get(uri, headers: _headers).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 首页推荐
  Future<List<VODItem>> home() async {
    final data = await _get({'ac': 'detail'});
    final list = (data['list'] as List<dynamic>?)
            ?.map((item) => VODItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
    return list;
  }

  /// 分类筛选
  Future<CategoryResult> category({
    String? t,
    String? cls,
    String? by,
    String? id,
    int page = 1,
  }) async {
    final params = <String, String>{'ac': 'detail', 'pg': '$page'};
    if (t != null) params['t'] = t;
    if (cls != null) params['class'] = cls;
    if (by != null) params['by'] = by;
    if (id != null) params['id'] = id;
    final data = await _get(params);
    return CategoryResult.fromJson(data);
  }

  /// 搜索
  Future<CategoryResult> search(String keyword, {int page = 1}) async {
    final data = await _get({'ac': 'detail', 'wd': keyword, 'pg': '$page'});
    return CategoryResult.fromJson(data);
  }

  /// 视频详情（含播放地址）
  Future<VODItem?> detail(String vodId) async {
    final data = await _get({'ac': 'detail', 'ids': vodId});
    final list = data['list'] as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    return VODItem.fromJson(list.first as Map<String, dynamic>);
  }
}