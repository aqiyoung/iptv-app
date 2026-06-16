// 卡 4 集成测试 — 主页 → 分类 → 详情 跳转流程
// 用内存 JSON fixture, 不依赖真 assets/data/channels_cn.json
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:iptv_app/core/router/router.dart';
import 'package:iptv_app/core/theme/theme.dart';
import 'package:iptv_app/data/models/channel.dart';
import 'package:iptv_app/data/repositories/channel_repository.dart';

const String _kFixtureJson = '''
[
  {"id":"CCTV1.cn","name":"CCTV-1","country":"CN","categories":["general"],"sources":["http://example.com/c1"]},
  {"id":"CCTV2.cn","name":"CCTV-2","country":"CN","categories":["business"],"sources":["http://example.com/c2"]},
  {"id":"HunanSatelliteTV.cn","name":"Hunan Satellite TV","country":"CN","categories":["general"],"sources":["http://example.com/hn"]},
  {"id":"BeijingTV.cn","name":"Beijing TV","country":"CN","categories":["general"],"sources":[]}
]
''';

class _FakeChannelRepository implements ChannelRepository {
  @override
  Future<List<Channel>> loadBundled() async => parseFromString(_kFixtureJson);

  @override
  List<Channel> parseFromString(String raw) {
    // Reuse the real implementation
    return const _RealRepo().parseFromString(raw);
  }

  @override
  void close() {}
}

class _RealRepo implements ChannelRepository {
  const _RealRepo();
  @override
  Future<List<Channel>> loadBundled() async => [];
  @override
  List<Channel> parseFromString(String raw) {
    return const ChannelRepository().parseFromString(raw);
  }

  @override
  void close() {}
}

void main() {
  testWidgets('home → category (cctv) → player', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelRepositoryProvider.overrideWithValue(_FakeChannelRepository()),
        ],
        child: MaterialApp.router(
          theme: IptvTheme.light(),
          routerConfig: buildRouter(),
        ),
      ),
    );

    // 等待 async channels 加载 + UI rebuild
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // 主页: 3 大分类都应出现
    expect(find.text('央视'), findsOneWidget);
    expect(find.text('卫视'), findsOneWidget);
    expect(find.text('地方'), findsOneWidget);
    expect(find.text('三页直播'), findsOneWidget);

    // 点击「央视」卡片
    await tester.tap(find.text('央视'));
    await tester.pumpAndSettle();

    // 分类页: 标题是「央视」, 2 个 CCTV 频道都出现
    expect(find.text('央视'), findsAtLeastNWidgets(1));
    expect(find.text('CCTV-1'), findsOneWidget);
    expect(find.text('CCTV-2'), findsOneWidget);
    expect(find.text('Hunan Satellite TV'), findsNothing);

    // 点击 CCTV-1 频道
    await tester.tap(find.text('CCTV-1'));
    await tester.pumpAndSettle();

    // 播放页: 顶部应显示 channelId
    expect(find.text('CCTV1.cn'), findsOneWidget);
    // 视频区占位文案
    expect(find.text('视频区'), findsOneWidget);
  });

  testWidgets('home → category (satellite) shows Hunan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelRepositoryProvider.overrideWithValue(_FakeChannelRepository()),
        ],
        child: MaterialApp.router(
          theme: IptvTheme.light(),
          routerConfig: buildRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.text('卫视'));
    await tester.pumpAndSettle();

    expect(find.text('Hunan Satellite TV'), findsOneWidget);
    expect(find.text('CCTV-1'), findsNothing);
  });

  testWidgets('back from category returns to home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelRepositoryProvider.overrideWithValue(_FakeChannelRepository()),
        ],
        child: MaterialApp.router(
          theme: IptvTheme.light(),
          routerConfig: buildRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // 进入 CCTV 分类
    await tester.tap(find.text('央视'));
    await tester.pumpAndSettle();
    expect(find.text('CCTV-1'), findsOneWidget);

    // 点击返回
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 回到主页
    expect(find.text('三页直播'), findsOneWidget);
    expect(find.text('CCTV-1'), findsNothing);
  });
}
