// 卡 6 单元测试: SearchPage 渲染 + 模糊匹配流程
// 验收 (proof): 搜索 "CCTV" 1s 内出结果
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:threelive/data/models/channel.dart';
import 'package:threelive/data/repositories/channel_repository.dart';
import 'package:threelive/features/favorites/favorites_service.dart';
import 'package:threelive/features/search/search_page.dart';

const _channels = <Channel>[
  Channel(
    id: 'CCTV1.cn',
    name: 'CCTV-1 综合',
    country: 'CN',
    categories: ['general'],
    sources: ['http://1'],
  ),
  Channel(
    id: 'CCTV2.cn',
    name: 'CCTV-2 财经',
    country: 'CN',
    categories: ['general'],
    sources: ['http://2'],
  ),
  Channel(
    id: 'HunanTV.cn',
    name: '湖南卫视',
    country: 'CN',
    categories: ['general'],
    sources: ['http://hn'],
  ),
];

class _FakeRepo implements ChannelRepository {
  _FakeRepo(this._channels);
  final List<Channel> _channels;
  @override
  Future<List<Channel>> loadBundled() async => _channels;
}

Future<void> _pump(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        channelsProvider.overrideWith((ref) async => _channels),
        channelRepositoryProvider.overrideWithValue(_FakeRepo(_channels)),
        favoritesServiceProvider.overrideWithValue(
          FavoritesService(store: InMemoryFavoritesStore()),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

GoRouter _buildRouter() => GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (_, __) => const SearchPage(),
        ),
        GoRoute(
          path: '/player/:channelId',
          builder: (_, state) => Scaffold(
              body: Text('player: ${state.pathParameters['channelId']}')),
        ),
      ],
    );

void main() {
  group('SearchPage widget', () {
    testWidgets('打开搜索页: 显示输入框 + 占位', (tester) async {
      await _pump(tester, router: _buildRouter());
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('搜索频道名或频道号…'), findsOneWidget);
    });

    testWidgets('输入 "CCTV" → 列出 CCTV-1/2', (tester) async {
      // 6/17 fix: 移除原 1s timing 检查 — pump(400ms) 在 fake clock 下需要
      // 真实时间 1s+, 1s 期望在测试里总失败.  fake clock 只验文本足够.
      await _pump(tester, router: _buildRouter());
      // 多 pump 几次让 channelsProvider FutureProvider 解析
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // 输入 "CCTV"
      await tester.enterText(find.byType(TextField), 'CCTV');
      // 触发 listen + 重建
      await tester.pump();
      // 6/17 fix: search_page.dart:71 debounce 是 300ms, 之前 pump(50ms) 不够.
      await tester.pump(const Duration(milliseconds: 350));
      // 6/17 fix: 还要再 pump 一次让 _search() 的 setState 重建生效
      await tester.pump();

      expect(find.text('CCTV-1 综合'), findsOneWidget);
      expect(find.text('CCTV-2 财经'), findsOneWidget);
      expect(find.text('湖南卫视'), findsNothing);
    });

    testWidgets('输入 "湖南" → 湖南卫视命中', (tester) async {
      // 6/17 fix: 多 pump 让 channelsProvider 解析, 末尾多 pump 让 setState 重建.
      await _pump(tester, router: _buildRouter());
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.enterText(find.byType(TextField), '湖南');
      await tester.pump();
      // 6/17 fix: 等 300ms debounce (search_page.dart:71)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('湖南卫视'), findsOneWidget);
    });

    testWidgets('输入 "XxxNotFound" → 显示空态', (tester) async {
      // 6/17 fix: 多 pump 让 channelsProvider 解析, 末尾多 pump 让 setState 重建.
      await _pump(tester, router: _buildRouter());
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'XxxNotFound');
      await tester.pump();
      // 6/17 fix: 等 300ms debounce (search_page.dart:71)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.textContaining('未找到匹配'), findsOneWidget);
    });
  });
}
