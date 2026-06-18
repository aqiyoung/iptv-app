import 'package:flutter_test/flutter_test.dart';
import 'package:sanyelive/data/category_zh.dart';

void main() {
  group('categoryZh', () {
    test('sports → 体育', () {
      expect(categoryZh('sports'), '体育');
    });

    test('news → 新闻', () {
      expect(categoryZh('news'), '新闻');
    });

    test('空字符串 → 空字符串', () {
      expect(categoryZh(''), '');
      expect(categoryZh(null), '');
    });

    test('未知 category → 原文', () {
      expect(categoryZh('unknown_category_xyz'), 'unknown_category_xyz');
    });

    test('大写也能匹配 (lowercase)', () {
      expect(categoryZh('SPORTS'), '体育');
      expect(categoryZh('News'), '新闻');
    });

    test('movies / music / kids', () {
      expect(categoryZh('movies'), '电影');
      expect(categoryZh('music'), '音乐');
      expect(categoryZh('kids'), '少儿');
    });
  });
}
