import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanyelive/services/smart_source_router.dart';

void main() {
  group('SmartSourceRouter', () {
    test('rankSources 按评分排序', () {
      final router = SmartSourceRouter();
      final urls = ['http://a.com', 'http://b.com', 'http://c.com'];
      final now = DateTime.now();
      final scores = {
        'http://a.com': SourceScore(
            url: 'http://a.com', score: 0.3, latencyMs: 500,
            successCount: 3, failCount: 2, lastTestedAt: now),
        'http://b.com': SourceScore(
            url: 'http://b.com', score: 0.9, latencyMs: 100,
            successCount: 9, failCount: 1, lastTestedAt: now),
        'http://c.com': SourceScore(
            url: 'http://c.com', score: 0.6, latencyMs: 300,
            successCount: 6, failCount: 4, lastTestedAt: now),
      };

      final ranked = router.rankSources(urls, scores);
      expect(ranked, ['http://b.com', 'http://c.com', 'http://a.com']);
    });

    test('recordResult 更新评分', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = SmartSourceRouter(prefs: prefs);

      const url = 'http://test.com/stream.m3u8';

      await router.recordResult(url, true);

      final scores = await router.getScores([url]);
      expect(scores[url]!.successCount, 1);
      expect(scores[url]!.failCount, 0);
    });
  });
}
