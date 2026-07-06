/// TVBox 配置文件解析器
///
/// 解析 wex.json / meow.json / m.json 等 TVBox 配置文件
/// 直接提取 MacCMS API (type=1) 站点和直播源 (lives)

import 'dart:convert';
import 'package:http/http.dart' as http;

class TVBoxConfig {
  final List<TVBoxSite> sites;
  final List<TVBoxLive> lives;
  final String spider;

  const TVBoxConfig({
    this.sites = const [],
    this.lives = const [],
    this.spider = '',
  });

  List<TVBoxSite> get macCMSSites =>
      sites.where((s) => s.type == 1 && s.api.contains('api.php/provide/vod')).toList();

  /// 从 URL 获取并解析 TVBox 配置
  static Future<TVBoxConfig> fetch(String url) async {
    final client = http.Client();
    try {
      final response = await client.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      return parse(response.body);
    } finally {
      client.close();
    }
  }

  /// 解析 TVBox JSON 文本（去掉 // 和 # 注释行）
  static TVBoxConfig parse(String text) {
    final cleanLines = text.split('\n').where((line) {
      final trimmed = line.trim();
      return !trimmed.startsWith('//') && !trimmed.startsWith('#');
    }).toList();
    final jsonStr = cleanLines.join('\n');
    final map = jsonDecode(jsonStr) as Map<String, dynamic>? ?? {};

    final sites = (map['sites'] as List<dynamic>?)
            ?.map((s) => TVBoxSite.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    final lives = (map['lives'] as List<dynamic>?)
            ?.expand((l) {
              final group = (l as Map<String, dynamic>)['group'] as String? ?? '';
              final channels = (l['channels'] as List<dynamic>?)
                      ?.map((c) {
                        final ch = c as Map<String, dynamic>;
                        return TVBoxLive(
                          group: group,
                          name: ch['name'] as String? ?? '',
                          urls: (ch['urls'] as List<dynamic>?)
                                  ?.map((u) => u.toString())
                                  .toList() ??
                              [],
                        );
                      })
                      .toList() ??
                  [];
              return channels;
            })
            .toList() ??
        [];

    return TVBoxConfig(
      sites: sites,
      lives: lives,
      spider: map['spider'] as String? ?? '',
    );
  }
}

class TVBoxSite {
  final String key;
  final String name;
  final int type;
  final String api;
  final String ext;
  final String jar;
  final bool searchable;
  final bool filterable;

  const TVBoxSite({
    this.key = '',
    this.name = '',
    this.type = 0,
    this.api = '',
    this.ext = '',
    this.jar = '',
    this.searchable = true,
    this.filterable = false,
  });

  factory TVBoxSite.fromJson(Map<String, dynamic> json) {
    return TVBoxSite(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as int? ?? 0,
      api: json['api'] as String? ?? '',
      ext: json['ext'] as String? ?? '',
      jar: json['jar'] as String? ?? '',
      searchable: json['searchable'] != 0,
      filterable: json['filterable'] != 0,
    );
  }
}

class TVBoxLive {
  final String group;
  final String name;
  final List<String> urls;

  const TVBoxLive({
    this.group = '',
    this.name = '',
    this.urls = const [],
  });
}