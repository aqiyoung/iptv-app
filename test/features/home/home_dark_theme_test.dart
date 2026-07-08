// 暗色主题测试 — 验证首页在暗色主题下正常渲染
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        channelsStreamProvider.overrideWith((ref) async* {
          yield _channels;
        }),
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

  group('HomePage dark theme', () {
    testWidgets('暗色主题: 首页正常渲染', (tester) async {
      await _pumpDark(tester);
      expect(find.text('视界'), findsWidgets);
    });

    testWidgets('暗色主题: 背景颜色正确', (tester) async {
      await _pumpDark(tester);
      // 验证暗色主题背景色
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF101010)));
    });
  });
}
