import 'package:flutter/material.dart';

import 'core/theme/colors.dart';
import 'core/theme/theme.dart';
import 'core/theme/typography.dart';
import 'widgets/category_card.dart';
import 'widgets/channel_tile.dart';
import 'widgets/serif_headline.dart';

void main() {
  runApp(const IptvApp());
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV',
      debugShowCheckedModeBanner: false,
      theme: IptvTheme.light(),
      home: const IptvDemoPage(),
    );
  }
}

/// Demo page — 卡 2 验收用：展示 3 个核心 widget 的样子
/// 后续会被卡 4「主页 + 分类页 + 频道列表 UI」替换
class IptvDemoPage extends StatelessWidget {
  const IptvDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const SerifHeadline(
              '三页直播',
              subtitle: '7,800+ 频道 · iptv-org 数据源',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '设计系统演示',
                style: IptvTypography.sansTitle.copyWith(
                  color: IptvColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // CategoryCard 演示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: CategoryCard(
                      title: '央视',
                      subtitle: 'CCTV-1 ~ CCTV-16',
                      icon: Icons.tv,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CategoryCard(
                      title: '卫视',
                      subtitle: '32 个省级卫视',
                      icon: Icons.public,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // SerifHeadline 在频道列表前
            const SerifHeadline(
              '热门频道',
              subtitle: '今日 TOP 10',
            ),
            // ChannelTile 演示
            const ChannelTile(
              channelNumber: '01',
              channelName: 'CCTV-1 综合',
              country: '中国大陆',
            ),
            const ChannelTile(
              channelNumber: '02',
              channelName: '湖南卫视',
              country: '中国大陆',
            ),
            const ChannelTile(
              channelNumber: '03',
              channelName: '浙江卫视',
              country: '中国大陆',
              isLive: false,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
