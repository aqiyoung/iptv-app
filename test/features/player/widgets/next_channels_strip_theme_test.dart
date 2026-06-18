// v0.3.5.4 主题适配真修: 浅色+暗色都验证 next_channels_strip chrome 颜色
//
// 验证:
//   1. 浅色主题下, 「下一频道」 section header 文字色用
//      colorScheme.onSurfaceVariant (跟浅米色页面配套).
//   2. 暗色主题下, 同样的 widget 用暗色板 (darkTextSecondary).
//
// 注意: chip 本身 (bgElevated / textPrimary / textSecondary / dividerWarm)
// 故意保留浅色 token, 因为 chip 浮在视频上 (黑底) — 需要高对比度,
// 不跟随 app 主题.  这一条 v0.3.6.1 hotfix 已经定下, 不变.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyelive/core/theme/colors.dart';
import 'package:sanyelive/core/theme/theme.dart';
import 'package:sanyelive/data/models/channel.dart';
import 'package:sanyelive/features/player/widgets/next_channels_strip.dart';

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
    id: 'CCTV3.cn',
    name: 'CCTV-3',
    country: 'CN',
    categories: ['general'],
    sources: ['http://3'],
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: NextChannelsStrip(
          currentChannelId: 'CCTV1.cn',
          allChannels: _channels,
          onChannelTap: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('NextChannelsStrip v0.3.5.4 主题适配 (浅色+暗色)', () {
    testWidgets('浅色主题: section header 文字色 = colorScheme.onSurfaceVariant (跟主题联动)',
        (tester) async {
      await _pump(tester, theme: IptvTheme.light());
      final header = tester.widget<Text>(find.text('下一频道'));
      expect(header, isNotNull);
      expect(header.style?.color, isNotNull);
      // 浅色下, section header 应该 = colorScheme.onSurfaceVariant
      // (由 ColorScheme.fromSeed 自动生成, 浅米色页面上是 #53433F 中棕)
      final ctx = tester.element(find.text('下一频道'));
      final expected = Theme.of(ctx).colorScheme.onSurfaceVariant;
      expect(header.style?.color, equals(expected),
          reason: '浅色下 section header = onSurfaceVariant (跟主题联动)');
      // 不应该是硬编码的浅色 token (textPrimary 0xFF2A2520 深棕)
      expect(header.style?.color, isNot(equals(IptvColors.textPrimary)),
          reason: 'section header 不该用浅色 token IptvColors.textPrimary');
    });

    testWidgets('暗色主题: section header 文字色 = colorScheme.onSurfaceVariant (跟主题联动)',
        (tester) async {
      await _pump(tester, theme: IptvTheme.dark());
      final header = tester.widget<Text>(find.text('下一频道'));
      expect(header, isNotNull);
      expect(header.style?.color, isNotNull);
      // 暗色下, section header 应该 = colorScheme.onSurfaceVariant
      final ctx = tester.element(find.text('下一频道'));
      final expected = Theme.of(ctx).colorScheme.onSurfaceVariant;
      expect(header.style?.color, equals(expected),
          reason: '暗色下 section header = onSurfaceVariant (跟主题联动)');
      // 不能是浅色 token textSecondary (0xFF6B5F54)
      expect(header.style?.color, isNot(equals(IptvColors.textSecondary)),
          reason: '暗色下不能用浅色 token IptvColors.textSecondary');
    });
  });
}
