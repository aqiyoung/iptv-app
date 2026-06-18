// v0.3.6.1 hotfix: 暗色主题 widget 适配 — home_page dark theme test
//
// 验证 HomePage 顶 bar 3 个 IconButton (search/favorite/settings) 都用 onSurface.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanyelive/core/theme/colors.dart';
import 'package:sanyelive/core/theme/theme.dart';
import 'package:sanyelive/data/models/channel.dart';
import 'package:sanyelive/data/repositories/channel_repository.dart';
import 'package:sanyelive/features/favorites/favorites_service.dart';
import 'package:sanyelive/features/home/home_page.dart';
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
  Channel(
    id: 'CCTV2.cn',
    name: 'CCTV-2',
    country: 'CN',
    categories: ['general'],
    sources: ['http://2'],
  ),
  Channel(
    id: 'HunanSatelliteTV.cn',
    name: 'Hunan TV',
    country: 'CN',
    categories: ['general'],
    sources: ['http://hn'],
  ),
];

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/search',
          builder: (_, __) => const Scaffold(body: Text('SEARCH')),
        ),
        GoRoute(
          path: '/favorites',
          builder: (_, __) => const Scaffold(body: Text('FAVORITES')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('SETTINGS')),
        ),
      ],
    );

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
      child: MaterialApp.router(
        theme: IptvTheme.dark(),
        routerConfig: _router(),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomePage dark theme (v0.3.6.1 hotfix)', () {
    testWidgets('3 个 AppBar icon button 颜色 = darkTextPrimary (onSurface)',
        (tester) async {
      await _pumpDark(tester);

      // search / favorite_border / settings_outlined
      for (final icon in [Icons.search, Icons.favorite_border, Icons.settings_outlined]) {
        final icons = tester.widgetList<Icon>(find.byIcon(icon));
        expect(icons, isNotEmpty, reason: '$icon not found');
        for (final i in icons) {
          expect(i.color, isNot(equals(IptvColors.textPrimary)),
              reason: '$icon still uses light token IptvColors.textPrimary');
          // dark theme 下应该用 darkTextPrimary
          expect(i.color, equals(IptvColors.darkTextPrimary),
              reason: '$icon should use darkTextPrimary in dark theme');
        }
      }
    });

    testWidgets('所有 Text 都不用浅色 token (除 accentTerracotta 这种主色)',
        (tester) async {
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
  });
}
