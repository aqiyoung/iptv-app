// 卡 6 单元测试: HomePage 集成 — 上次观看 / 搜索入口 / 频道分类
// 验收 (proof): 收藏 5 个频道, 重启 APP 仍在; 搜索 "CCTV" 1s 内出结果

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanyelive/core/theme/theme.dart';
import 'package:sanyelive/data/models/channel.dart';
import 'package:sanyelive/data/repositories/channel_repository.dart';
import 'package:sanyelive/features/favorites/favorites_service.dart';
import 'package:sanyelive/features/home/home_page.dart';
import 'package:sanyelive/services/startup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _FakeRepo implements ChannelRepository {
  const _FakeRepo(this._channels);
  final List<Channel> _channels;
  @override
  Future<List<Channel>> loadBundled() async => _channels;
}

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => const Scaffold(body: Text('SEARCH_PAGE')),
        ),
        GoRoute(
          path: '/player/:channelId',
          builder: (_, state) => Scaffold(
            body: Text('PLAYER: ${state.pathParameters['channelId']}'),
          ),
        ),
        GoRoute(
          path: '/category/:catId',
          builder: (_, state) => Scaffold(
            body: Text('CATEGORY: ${state.pathParameters['catId']}'),
          ),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester, {
  required GoRouter router,
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: IptvTheme.light(),
        routerConfig: router,
      ),
    ),
  );
}

List<Override> _baseOverrides() => [
      channelsProvider.overrideWith((ref) async => _channels),
      channelsStreamProvider.overrideWith((ref) async* {
        yield _channels;
      }),
      channelRepositoryProvider.overrideWithValue(const _FakeRepo(_channels)),
      favoritesServiceProvider.overrideWithValue(
        FavoritesService(store: InMemoryFavoritesStore()),
      ),
    ];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomePage', () {
    testWidgets('渲染: PosterWallPage 正常渲染', (tester) async {
      await _pump(
        tester,
        router: _router(),
        overrides: [
          ..._baseOverrides(),
          startupServiceProvider.overrideWithValue(StartupService()),
        ],
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.text('视界'), findsWidgets);
    });
  });
}
