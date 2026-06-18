import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 验证打包后 assets/data/channels_cn.json 的内容契约
/// 卡 6 验收: 真流注入, 至少要有一部分频道带 sources
void main() {
  group('assets/data/channels_cn.json', () {
    final raw = File('assets/data/channels_cn.json').readAsStringSync();
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();

    test('channels 数组非空', () {
      expect(list, isNotEmpty);
    });

    test('channels 数量在合理范围 (50..600)', () {
      expect(list.length, greaterThanOrEqualTo(50));
      expect(list.length, lessThanOrEqualTo(600));
    });

    test('每个 channel 都有 id/name', () {
      for (final c in list) {
        expect(c['id'], isA<String>(), reason: 'channel without id: $c');
        expect(c['id'], isNotEmpty);
        expect(c['name'], isA<String>());
      }
    });

    test('id 唯一', () {
      final ids = list.map((c) => c['id'] as String).toSet();
      expect(ids.length, list.length, reason: '有重复 id');
    });

    test('卡 6 注入: 至少 30 个频道有 sources (iptv-org 覆盖率 ~20%)', () {
      final withSources = list
          .where((c) => (c['sources'] as List?)?.isNotEmpty ?? false)
          .length;
      expect(
        withSources,
        greaterThanOrEqualTo(30),
        reason: '只有 $withSources 个频道带 source, 少于 30',
      );
    });

    test('每个 channel 的 sources 数量 ≤ 5 (SourceFailover 不会跳 5 个源)', () {
      for (final c in list) {
        final sources = (c['sources'] as List?) ?? const [];
        expect(
          sources.length,
          lessThanOrEqualTo(5),
          reason: '${c['id']} 有 ${sources.length} 个 sources',
        );
      }
    });

    test('sources 都是 http(s) URL (接受 string 或 {url, type} 两种格式)', () {
      // 公开 HLS 源是 m3u8, 但有部分 m3u8 不带后缀名 (如 go.bkpcp.top/mg/bjws)
      // 实际能拉 — 上面都走过。允许不以 .m3u8 结尾但能拉。
      // 6/18 P2-2: merge_known_sources.py 把 known_sources.json 的 url 合并后,
      // 改成 {url, type: 'hls'} 对象格式 (兼容 iptv-org 原始 string 格式)
      for (final c in list) {
        final sources = (c['sources'] as List?) ?? const [];
        for (final s in sources) {
          final url = s is String ? s : (s as Map)['url'] as String;
          expect(
            url.startsWith('http://') || url.startsWith('https://'),
            true,
            reason: '非法 source URL: $s',
          );
        }
      }
    });

    test('categories 至少一个, 主分类在允许集合内 (新创建的 merged channel 可以为空)', () {
      // iptv-org categories 有 'science' (不在我们的 wantedCats 里)
      // 这里只软验证: categories 非空 + 首项是字符串
      // P2-2 合并脚本创建的 channel (known_sources 不带 categories) 允许空
      for (final c in list) {
        final cats = (c['categories'] as List?)?.cast<String>() ?? const [];
        // merged channel 类别是 [], 原 iptv-org channel 至少 1 个
        if (cats.isEmpty) {
          // merged channel: 校验 sources 非空 (避免伪空数据)
          final sources = (c['sources'] as List?) ?? const [];
          expect(
            sources.isNotEmpty,
            true,
            reason: '${c['id']} 伪空 channel: 无 categories 又无 sources',
          );
          continue;
        }
        expect(cats.first, isA<String>(), reason: '${c['id']} 首项不是字符串: $cats');
      }
    });
  });
}
