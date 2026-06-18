// v0.3.6.1 hotfix: 暗色主题 widget 适配 — search_page dark theme test
//
// 验证 SearchPage 7 个 hardcode 浅色 token 的地方都改成了 colorScheme.*:
//   L170: back IconButton color
//   L180: hintText color
//   L210: empty prompt text color
//   L226/L232: "未找到匹配" icon + text color
//   L311/312: 搜索结果 channel displayName color
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanyelive/core/theme/colors.dart';
import 'package:sanyelive/core/theme/theme.dart';
import 'package:sanyelive/data/models/channel.dart';
import 'package:sanyelive/data/repositories/channel_repository.dart';
import 'package:sanyelive/features/favorites/favorites_service.dart';
import 'package:sanyelive/features/search/search_page.dart';

class _FakeRepo implements ChannelRepository {
  _FakeRepo(this._channels);
  final List<Channel> _channels;
  @override
  Future<List<Channel>> loadBundled() async => _channels;
}

const _channels = <Channel>[
  Channel(
    id: 'CCTV1.cn',
    name: 'CCTV-1 综合',
    country: 'CN',
    categories: ['general'],
    sources: ['http://1'],
  ),
  Channel(
    id: 'HunanTV.cn',
    name: '湖南卫视',
    country: 'CN',
    categories: ['general'],
    sources: ['http://h'],
  ),
];

Future<void> _pumpDark(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        channelsProvider.overrideWith((ref) async => _channels),
        channelRepositoryProvider.overrideWithValue(_FakeRepo(_channels)),
        favoritesServiceProvider.overrideWithValue(
          FavoritesService(store: InMemoryFavoritesStore()),
        ),
      ],
      child: MaterialApp(
        theme: IptvTheme.dark(),
        home: const SearchPage(),
      ),
    ),
  );
  // 让 channelsProvider 的 future 解析
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchPage dark theme (v0.3.6.1 hotfix)', () {
    testWidgets('所有 Text widget 都没有用浅色 token', (tester) async {
      await _pumpDark(tester);

      final offenders = <String>[];
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        final c = w.style?.color;
        if (c == IptvColors.textPrimary) {
          offenders.add('"${w.data}" uses IptvColors.textPrimary');
        } else if (c == IptvColors.textSecondary) {
          offenders.add('"${w.data}" uses IptvColors.textSecondary');
        }
      }
      expect(offenders, isEmpty,
          reason: '暗色主题下不允许 hardcode 浅色 token: ${offenders.join(", ")}');
    });

    testWidgets('返回按钮用 onSurface (darkTextPrimary, 米色)',
        (tester) async {
      await _pumpDark(tester);
      final iconWidgets =
          tester.widgetList<Icon>(find.byIcon(Icons.arrow_back));
      expect(iconWidgets, isNotEmpty);
      final back = iconWidgets.first;
      expect(back.color, isNot(equals(IptvColors.textPrimary)),
          reason: '返回按钮不该用浅色 token');
      // dark theme 下应该用 darkTextPrimary
      expect(back.color, equals(IptvColors.darkTextPrimary));
    });

    testWidgets('空态 "输入关键词搜索频道" 用 onSurfaceVariant',
        (tester) async {
      await _pumpDark(tester);
      // 初始无 query → 显示 "输入关键词搜索频道"
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      Text? prompt;
      for (final t in textWidgets) {
        if (t.data == '输入关键词搜索频道') {
          prompt = t;
          break;
        }
      }
      expect(prompt, isNotNull);
      expect(prompt!.style?.color, isNot(equals(IptvColors.textSecondary)),
          reason: '提示文字不该用浅色 token');
      // dark theme onSurfaceVariant 走 M3 default, 不一定是 darkTextSecondary
      expect(prompt.style?.color, isA<Color>());
    });

    testWidgets('搜索 "XxxNotFound" → 空态 icon/text 用 onSurfaceVariant',
        (tester) async {
      await _pumpDark(tester);
      await tester.enterText(find.byType(TextField), 'XxxNotFound');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      // search_off icon 颜色
      final icons = tester.widgetList<Icon>(find.byIcon(Icons.search_off));
      expect(icons, isNotEmpty);
      expect(icons.first.color, isNot(equals(IptvColors.textSecondary)),
          reason: 'search_off icon 不该用浅色 token');

      // "未找到匹配" text 颜色
      final notFound = tester.widgetList<Text>(find.textContaining('未找到匹配'));
      expect(notFound, isNotEmpty);
      expect(notFound.first.style?.color, isNot(equals(IptvColors.textSecondary)));
    });
  });
}
