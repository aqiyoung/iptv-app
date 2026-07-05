import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/channel.dart';
import '../../../data/models/content.dart';
import '../../../data/mock/mock_contents.dart';
import '../../../data/repositories/channel_repository.dart';
import '../../core/theme/colors.dart';

/// 三页影视 首页
class PosterWallPage extends ConsumerWidget {
  const PosterWallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: IptvColors.bgParchment,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏
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
            const Expanded(child: _HomeTabs()),
          ],
        ),
      ),
    );
  }
}

class _HomeTabs extends ConsumerStatefulWidget {
  const _HomeTabs();

  @override
  ConsumerState<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends ConsumerState<_HomeTabs> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(3, (i) {
              const tabs = ['首页', '点播', '收藏'];
              final active = i == _currentTab;
              return GestureDetector(
                onTap: () => setState(() => _currentTab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
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
        Expanded(
          child: switch (_currentTab) {
            0 => const _HomeScreenContent(),
            1 => const _VodScreenContent(),
            _ => const _ComingSoonScreen(),
          },
        ),
      ],
    );
  }
}

// ════════════════════════════ 首页 ════════════════════════════

class _HomeScreenContent extends ConsumerWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Channel>>(
      future: ref.read(channelRepositoryProvider).loadBundled(),
      builder: (context, snapshot) {
        final channels = snapshot.data ?? [];
        return CustomScrollView(
          slivers: [
            // ── 1. 横幅轮播 ──
            SliverToBoxAdapter(
              child: _HeroBanner(movies: kMockMovies),
            ),
            // ── 2. 分类入口 ──
            SliverToBoxAdapter(
              child: _CategoryRow(onTap: (i) {
                const routes = ['/category/cctv', '/category/satellite', '/category/local'];
                if (i < routes.length) context.go(routes[i]);
              }),
            ),
            // ── 3. 正在直播 ──
            if (channels.isNotEmpty)
              SliverToBoxAdapter(
                child: _LiveNowSection(
                  channels: channels,
                  onPlay: (ch) => context.go('/player/${ch.id}'),
                ),
              ),
            // ── 4. 热门推荐 ──
            SliverToBoxAdapter(
              child: _buildPosterSection(context, '🔥 热门推荐', kMockRecommended),
            ),
            // ── 5. 电影/电视剧/综艺 ──
            SliverToBoxAdapter(
              child: _buildPosterSection(context, '🎬 电影', kMockMovies),
            ),
            SliverToBoxAdapter(
              child: _buildPosterSection(context, '📺 电视剧', kMockSeries),
            ),
            if (kMockVariety.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildPosterSection(context, '🎤 综艺', kMockVariety),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

// ── 1. 横幅轮播 ──

class _HeroBanner extends StatefulWidget {
  final List<Content> movies;
  const _HeroBanner({required this.movies});

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  late PageController _pageCtrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.movies.take(5).toList();
    return SizedBox(
      height: 190,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: items.length,
              itemBuilder: (_, i) => _heroCard(items[i], context),
            ),
          ),
          const SizedBox(height: 6),
          // dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _page == i
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(Content movie, BuildContext context) {
    final hue = (movie.title.codeUnitAt(0) * 37 + 120) % 360;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.30).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.50, 0.12).toColor(),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 标题大字号
          Positioned(
            left: 20,
            top: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie.year != null)
                  Text(movie.year!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                SizedBox(
                  width: 200,
                  child: Text(movie.title,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2)),
                ),
                const SizedBox(height: 6),
                if (movie.rating != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: movie.rating! >= 9.0
                          ? const Color(0xFFE65100)
                          : Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: Color(0xFFFFD600)),
                        const SizedBox(width: 3),
                        Text(movie.displayRating,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                if (movie.genres.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: movie.genres.map((g) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(g,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        )).toList(),
                  ),
              ],
            ),
          ),
          // 右下角大装饰字
          Positioned(
            right: -10,
            bottom: -10,
            child: Text(
              movie.title.characters.first,
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // 播放按钮
          Positioned(
            right: 16,
            top: 16,
            child: IconButton(
              icon: Icon(Icons.play_circle_fill,
                  color: theme.colorScheme.primary,
                  size: 36),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(movie.title),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. 分类入口 ──

class _CategoryRow extends StatelessWidget {
  final void Function(int index) onTap;
  const _CategoryRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cats = [
      ('📺', '电视直播'),
      ('🎬', '电影'),
      ('📺', '电视剧'),
      ('🎤', '综艺'),
      ('📚', '纪录片'),
      ('🆕', '新闻'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(cats.length, (i) {
          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(cats[i].$1,
                          style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(height: 4),
                Text(cats[i].$2,
                    style: const TextStyle(fontSize: 11, height: 1.2)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── 3. 正在直播 ──

class _LiveNowSection extends StatelessWidget {
  final List<Channel> channels;
  final void Function(Channel) onPlay;
  const _LiveNowSection({required this.channels, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final first = channels.isNotEmpty ? channels.first : null;
    final rest =
        channels.length > 1 ? channels.sublist(1, min(6, channels.length)) : <Channel>[];
    final cardW = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              const Text('正在直播',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/category/cctv'),
                child: Row(children: [
                  Text('查看全部',
                      style: TextStyle(
                          fontSize: 13, color: IptvColors.textSecondary)),
                  Icon(Icons.chevron_right,
                      size: 18, color: IptvColors.textSecondary)
                ]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 直播卡片
          SizedBox(
            height: 110,
            child: Row(
              children: [
                // 主频道
                if (first != null)
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => onPlay(first),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: _channelGradient(first),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(first.displayName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  const Text('直播中',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Icon(Icons.play_circle_fill,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // 右侧频道列表
                Expanded(
                  flex: 2,
                  child: Column(
                    children: List.generate(
                      min(rest.length, 4),
                      (i) => Expanded(
                        child: GestureDetector(
                          onTap: () => onPlay(rest[i]),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  rest[i].displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Gradient _channelGradient(Channel ch) {
    final hash = (ch.displayName.codeUnitAt(0) * 33 + 60) % 360;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromAHSL(1, hash.toDouble(), 0.55, 0.30).toColor(),
        HSLColor.fromAHSL(1, (hash + 30) % 360, 0.50, 0.15).toColor(),
      ],
    );
  }
}

// ── 海报区块 (通用) ──

Widget _buildPosterSection(
    BuildContext context, String title, List<Content> items) {
  const cardWidth = 115.0;
  const cardHeight = cardWidth / 0.7;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
          ],
        ),
      ),
      SizedBox(
        height: cardHeight + 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) =>
              _PosterCard(content: items[i], width: cardWidth, height: cardHeight),
        ),
      ),
    ],
  );
}

// ════════════════════════════ 点播 ════════════════════════════

class _VodScreenContent extends StatelessWidget {
  const _VodScreenContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildPosterSection(context, '🎬 电影推荐', kMockMovies),
        _buildPosterSection(context, '📺 电视剧', kMockSeries),
        if (kMockVariety.isNotEmpty)
          _buildPosterSection(context, '🎤 综艺', kMockVariety),
      ],
    );
  }
}

// ════════════════════════════ 海报卡片 ════════════════════════════

class _PosterCard extends StatelessWidget {
  const _PosterCard(
      {required this.content,
      required this.width,
      required this.height});

  final Content content;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hue = (content.title.codeUnitAt(0) * 47 + 120) % 360;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放: ${content.title}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.35)
                          .toColor(),
                      HSLColor.fromAHSL(1, (hue + 45) % 360, 0.50, 0.15)
                          .toColor(),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (content.rating != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: content.rating! >= 9.0
                                ? const Color(0xFFE65100)
                                : Colors.black45,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 10, color: Color(0xFFFFD600)),
                              const SizedBox(width: 2),
                              Text(content.displayRating,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    if (content.genres.isNotEmpty)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(content.genres.first,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 9)),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          content.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: width,
              child: Text(content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            if (content.subtitle != null || content.year != null)
              Text(
                content.subtitle ?? content.year ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10, color: IptvColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════ Coming Soon ════════════════════════════

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 64, color: IptvColors.textSecondary),
          const SizedBox(height: 16),
          const Text('收藏功能开发中…',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('即将上线，敬请期待',
              style:
                  TextStyle(fontSize: 13, color: IptvColors.textSecondary)),
        ],
      ),
    );
  }
}