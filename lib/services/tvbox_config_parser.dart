// v0.3.13.0 (7/9 老板要求): TVBox JSON 源文件解析 — 提取 type:1 MacCMS 源.
//
// 这 4 个 URL 是行业公开的 TVBox / 影视聚合配置 (俗称 "盒子源"):
//   - TVBox 格式顶层 { spider, sites[], lives[], rules[], parses[] }
//   - sites[] 每个站点 { key, name, type, api, searchable, ... }
//   - type:  1 = MacCMS JSON API (直接 ac=list/detail,  我们的 VodApiService
//               能直接用),  2/3 = Spider JS 采集 (需 JS 引擎,  Flutter 跑不了)
//
// 我们只取 type == 1 且 api 非空的站点,  转成 VodSource.
//
// 容错:  单个 URL 拉取失败 / 超时 / 非 JSON / 无 type:1 站点 → 跳过该 URL
// (不抛错),  返回其他 URL 解析成功的.  跟 app 现有 IPv4 / 远程容错一致.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/vod_source.dart';

/// 4 个公开 TVBox 聚合源 URL (老板 7/9 给出).
const List<String> kTvBoxSourceUrls = [
  'https://9280.kstore.space/wex.json',
  'https://dxawi.github.io/0/0.json',
  'https://raw.liucn.cc/box/m.json',
  'https://github.com/YuanHsing/freed/raw/master/TVBox/meow.json',
];

/// 单 URL 拉取超时.
const Duration kTvBoxFetchTimeout = Duration(seconds: 15);

class TvBoxConfigParser {
  TvBoxConfigParser({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// 拉取所有 TVBox URL,  解析出 type:1 MacCMS 站点,  去重 (同 host 留第一个).
  /// 失败 URL 静默跳过.
  Future<List<VodSource>> fetchTvBoxSources({
    List<String> urls = kTvBoxSourceUrls,
  }) async {
    final found = <String, VodSource>{}; // host → source (去重)
    for (final url in urls) {
      final sources = await _fetchOne(url);
      for (final s in sources) {
        if (s.baseUrl.isEmpty) continue;
        final host = s.host;
        if (found.containsKey(host)) continue; // 同 host 留第一个
        found[host] = s;
      }
    }
    return found.values.toList();
  }

  /// 拉取单个 TVBox URL → type:1 VodSource 列表.
  Future<List<VodSource>> _fetchOne(String url) async {
    try {
      final resp =
          await _client.get(Uri.parse(url)).timeout(kTvBoxFetchTimeout);
      if (resp.statusCode != 200) {
        debugPrint('TvBoxParser: $url → HTTP ${resp.statusCode}, skip');
        return [];
      }
      // 这 4 个 URL 有些在 JSON 前带 // 或 # 注释行 (如 m.json),  清理掉.
      final cleaned = _stripComments(resp.body);
      final decoded = json.decode(cleaned);
      if (decoded is! Map<String, dynamic>) return [];
      final sites = decoded['sites'];
      if (sites is! List) return [];

      final List<VodSource> result = [];
      for (final site in sites) {
        if (site is! Map<String, dynamic>) continue;
        // 只取 type:1 (MacCMS JSON API).  type:2/3 是 JS spider,  跳过.
        final type = site['type'];
        if (type is! int || type != 1) continue;
        final api = (site['api'] as String?)?.trim() ?? '';
        if (api.isEmpty) continue;
        final rawName = (site['name'] as String?)?.trim() ?? '';
        if (rawName.isEmpty) continue;
        final name = VodSource.cleanName(rawName);
        // id = host + 序号 (避免同 URL 内重名).
        String host;
        try {
          host = Uri.parse(api).host;
        } catch (_) {
          host = 'tvbox';
        }
        result.add(VodSource(
          id: '${host}_${result.length}',
          name: name,
          baseUrl: api,
          typeIds: bfzyapiTypeIds, // 预设 bfzyapi 系 (采集器大多兼容)
        ));
      }
      debugPrint('TvBoxParser: $url → ${result.length} type:1 sources');
      return result;
    } catch (e) {
      debugPrint('TvBoxParser: $url fetch failed: $e');
      return [];
    }
  }

  /// 去掉 JSON 前导的 //xxx 和 #xxx 注释行 (m.json 第一行有 // 中文注释).
  String _stripComments(String raw) {
    final lines = raw.split('\n');
    final buf = StringBuffer();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//') || trimmed.startsWith('#')) continue;
      buf.writeln(line);
    }
    return buf.toString();
  }

  void dispose() {
    _client.close();
  }
}

void debugPrint(String msg) {
  // ignore: avoid_print
  print(msg);
}
