import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/channel.dart';
import '../../../data/repositories/channel_repository.dart';
import '../../core/theme/colors.dart';

/// 三页影视 海报墙首页
class PosterWallPage extends ConsumerWidget {
  const PosterWallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        children: [
            // 顶部搜索栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('三页影视',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context.go('/search'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.go('/settings'),
                  ),
                ],
              ),
            ),
            // 内容
            const Expanded(child: _PosterWallTabs()),
          ],
        ),
      );
  }
}

class _PosterWallTabs extends ConsumerStatefulWidget {
  const _PosterWallTabs();

  @override
  ConsumerState<_PosterWallTabs> createState() => _PosterWallTabsState();
}

class _PosterWallTabsState extends ConsumerState<_PosterWallTabs> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab 栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(3, (i) {
              const tabs = ['直播', '点播', '收藏'];
              final active = i == _currentTab;
              return GestureDetector(
                onTap: () => setState(() => _currentTab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                      color: active
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // 内容
        Expanded(
          child: _currentTab == 0 ? const _LiveScreenContent() : _ComingSoonScreen(tab: _currentTab),
        ),
      ],
    );
  }
}

class _LiveScreenContent extends ConsumerWidget {
  const _LiveScreenContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Channel>>(
      future: ref.read(channelRepositoryProvider).loadBundled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                const Text('加载失败', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(snapshot.error.toString(), style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(channelRepositoryProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        final channels = snapshot.data ?? [];
        // 分组
        final cctv = <Channel>[];
        final satellite = <Channel>[];
        final local = <Channel>[];
        for (final ch in channels) {
          if (ch.categories.contains('央视')) {
            cctv.add(ch);
          } else if (ch.categories.contains('卫视')) {
            satellite.add(ch);
          } else {
            local.add(ch);
          }
        }
        return ListView(
          children: [
            if (cctv.isNotEmpty) _buildSection(context, '📺 央视频道', cctv, () => context.go('/category/cctv')),
            if (satellite.isNotEmpty) _buildSection(context, '📡 卫视频道', satellite, () => context.go('/category/satellite')),
            if (local.isNotEmpty) _buildSection(context, '🏙️ 地方频道', local, () => context.go('/category/local')),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Channel> items, VoidCallback onSeeAll) {
    final cardWidth = MediaQuery.of(context).size.width > 600 ? 130.0 : 95.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(onTap: onSeeAll, child: Row(children: [Text('查看全部', style: TextStyle(fontSize: 13, color: IptvColors.textSecondary)), Icon(Icons.chevron_right, size: 18, color: IptvColors.textSecondary)])),
            ],
          ),
        ),
        SizedBox(
          height: cardWidth / 0.65 + 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ChannelCard(channel: items[i], width: cardWidth),
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.channel, required this.width});

  final Channel channel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width / 0.65;
    return GestureDetector(
      onTap: () => context.go('/player/${channel.id}'),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: width,
                height: height,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                    ? Image.network(channel.logoUrl!, fit: BoxFit.contain, width: width, errorBuilder: (_, __, ___) => _Initial(firstChar(channel.displayName)))
                    : _Initial(firstChar(channel.displayName)),
              ),
            ),
            const SizedBox(height: 6),
            Text(channel.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(this.char);
  final String char;
  @override
  Widget build(BuildContext context) => Center(child: Text(char, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)));
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.tab});
  final int tab;

  @override
  Widget build(BuildContext context) {
    final info = tab == 1 ? ('点播', Icons.movie) : ('收藏', Icons.favorite);
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(info.$2, size: 64, color: IptvColors.textSecondary), const SizedBox(height: 16), Text('${info.$1}功能开发中…', style: const TextStyle(fontSize: 16)), const SizedBox(height: 8), Text('即将上线，敬请期待', style: TextStyle(fontSize: 13, color: IptvColors.textSecondary))]));
  }
}

String firstChar(String s) => s.isNotEmpty ? s[0] : '?';
