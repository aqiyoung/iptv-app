// v0.3.6.1 hotfix: 暗色主题 widget 适配 — next_channels_strip dark theme test
//
// 验证 L57 「下一频道」 section 标题用 onSurfaceVariant.
// 注意: chip 本身 (L126, 147, 160, 161, 185, 196) 故意保留浅色 token,
// 因为 chip 浮在视频上 (黑底) — 需要高对比度, 不跟随 app 主题.
// 范围严格按 task spec: 只 L57.
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

Future<void> _pumpDark(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: IptvTheme.dark(),
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
  group('NextChannelsStrip dark theme (v0.3.6.1 hotfix)', () {
    testWidgets('「下一频道」 section header 文字色 != textSecondary 浅色 token',
        (tester) async {
      await _pumpDark(tester);
      final header = tester.widget<Text>(find.text('下一频道'));
      expect(header, isNotNull);
      // L57 之前 hardcode textSecondary, 现在用 onSurfaceVariant
      expect(header.style?.color, isNotNull);
      expect(header.style?.color, isNot(equals(IptvColors.textSecondary)),
          reason: '「下一频道」 section header 不该用浅色 token IptvColors.textSecondary');
    });
  });
}
