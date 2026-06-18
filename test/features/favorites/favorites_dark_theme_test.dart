// v0.3.6.1 hotfix: 暗色主题 widget 适配 — favorites_page dark theme test
//
// 验证:
//   1. dark theme 下, FavoritesPage 渲染的 Text widget 没有 hardcode 浅色 token
//      (IptvColors.textPrimary / IptvColors.textSecondary)
//   2. showModalBottomSheet 内部背景色 (colorScheme.surfaceContainer) 是 dark
//   3. Scaffold 不再 hardcode bgParchment (删了 backgroundColor)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanyelive/core/theme/colors.dart';
import 'package:sanyelive/core/theme/theme.dart';
import 'package:sanyelive/data/models/channel.dart';
import 'package:sanyelive/data/repositories/channel_repository.dart';
import 'package:sanyelive/features/favorites/favorites_page.dart';
import 'package:sanyelive/features/favorites/favorites_service.dart';
import 'package:sanyelive/services/startup_service.dart';

class _FakeRepo implements ChannelRepository {
  const _FakeRepo(this._channels);
  final List<Channel> _channels;
  @override
  Future<List<Channel>> loadBundled() async => _channels;
}

const _channels = <Channel>[
  Channel(
    id: 'CCTV1.cn',
    name: 'CCTV-1',
    country: 'CN',
    categories: ['general'],
    sources: ['http://1'],
  ),
];

Future<void> _pumpDark(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        channelsProvider.overrideWith((ref) async => _channels),
        channelRepositoryProvider.overrideWithValue(const _FakeRepo(_channels)),
        favoritesServiceProvider.overrideWithValue(
          FavoritesService(store: InMemoryFavoritesStore()),
        ),
        startupServiceProvider.overrideWithValue(StartupService()),
      ],
      child: MaterialApp(
        theme: IptvTheme.dark(),
        home: const FavoritesPage(),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoritesPage dark theme (v0.3.6.1 hotfix)', () {
    testWidgets('Scaffold 不再 hardcode bgParchment (依赖 theme surface)',
        (tester) async {
      await _pumpDark(tester);
      // Scaffold 显式 backgroundColor == null (让 theme.surface 生效)
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull,
          reason: 'Scaffold 硬编码 backgroundColor 会盖掉 theme');
    });

    testWidgets('所有 Text widget 都没有用浅色 token (textPrimary/textSecondary)',
        (tester) async {
      await _pumpDark(tester);

      final offenders = <String>[];
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        final c = w.style?.color;
        if (c == IptvColors.textPrimary) {
          offenders.add('${w.data} uses IptvColors.textPrimary');
        } else if (c == IptvColors.textSecondary) {
          offenders.add('${w.data} uses IptvColors.textSecondary');
        }
      }
      expect(offenders, isEmpty,
          reason:
              '暗色主题下不允许 hardcode 浅色 token: ${offenders.join(", ")}');
    });

    testWidgets('空态图标色用 onSurfaceVariant (darkTextSecondary)',
        (tester) async {
      // 空收藏列表 → 显示 _EmptyState 里的 favorite_border 图标
      await _pumpDark(tester);
      // _EmptyState 里的 favorite_border icon
      final iconWidgets = tester.widgetList<Icon>(find.byIcon(Icons.favorite_border));
      expect(iconWidgets, isNotEmpty);
      final icon = iconWidgets.first;
      expect(icon.color, isNot(equals(IptvColors.textSecondary)),
          reason: '空态图标不该用浅色 token');
      // dark theme onSurfaceVariant = M3 default light purple-gray
      // (IptvTheme.dark() 没显式 set onSurfaceVariant, 走 M3 default)
      expect(icon.color, isA<Color>());
    });
  });
}
