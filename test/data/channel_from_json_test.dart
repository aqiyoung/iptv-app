import 'package:flutter_test/flutter_test.dart';
import 'package:sanyelive/data/models/channel.dart';

void main() {
  group('Channel.fromJson', () {
    test('string 格式 source 正常解析', () {
      final c = Channel.fromJson({
        'id': 'Test.cn',
        'name': 'Test',
        'country': 'CN',
        'categories': ['news'],
        'sources': ['http://a.com/1.m3u8', 'https://b.com/2.m3u8'],
      });
      expect(c.id, 'Test.cn');
      expect(c.sources, <String>[
        'http://a.com/1.m3u8',
        'https://b.com/2.m3u8',
      ]);
    });

    test('dict 格式 source ({url, type}) 也能解析, v0.3.5.1 修', () {
      // v0.3.5.1 修: merge_known_sources.py 把 known_sources.json 合并后
      // 改成 {url, type} 对象格式, 之前 .cast<String>() 在 dict 上 view
      // 不报错, 但访问 TypeError, CCTV-5 加载不出来可能正是这原因.
      final c = Channel.fromJson({
        'id': 'CCTV5.cn',
        'name': 'CCTV-5',
        'country': 'CN',
        'categories': ['sports'],
        'sources': [
          {
            'url': 'http://ottrrs.hl.chinamobile.com/PLTV/index.m3u8',
            'type': 'hls'
          },
          {'url': 'https://live.fanmingming.com/cctv5.m3u8', 'type': 'hls'},
        ],
      });
      expect(c.id, 'CCTV5.cn');
      expect(c.sources, <String>[
        'http://ottrrs.hl.chinamobile.com/PLTV/index.m3u8',
        'https://live.fanmingming.com/cctv5.m3u8',
      ]);
    });

    test('string + dict 混存也能解析 (channels_cn.json 真实情况)', () {
      final c = Channel.fromJson({
        'id': 'Mixed.cn',
        'name': 'Mixed',
        'country': 'CN',
        'categories': ['general'],
        'sources': [
          'http://string-format.com/1.m3u8',
          {'url': 'http://dict-format.com/2.m3u8', 'type': 'hls'},
        ],
      });
      expect(c.sources, <String>[
        'http://string-format.com/1.m3u8',
        'http://dict-format.com/2.m3u8',
      ]);
    });

    test('空 sources [] → 空 list', () {
      final c = Channel.fromJson({
        'id': 'Empty.cn',
        'name': 'Empty',
        'country': 'CN',
        'categories': ['news'],
        'sources': <dynamic>[],
      });
      expect(c.sources, isEmpty);
    });

    test('缺 sources 字段 → 空 list (向后兼容)', () {
      final c = Channel.fromJson({
        'id': 'NoSources.cn',
        'name': 'NoSources',
        'country': 'CN',
        'categories': ['news'],
      });
      expect(c.sources, isEmpty);
    });
  });
}
