import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/channel.dart';
import '../../../data/models/content.dart';
import '../../../data/mock/mock_contents.dart';
import '../../../data/repositories/channel_repository.dart';
import '../../core/theme/colors.dart';

/// 三页影视 首页 — 浅色模式 · 1:1 复刻参考图
class PosterWallPage extends ConsumerStatefulWidget {
  const PosterWallPage({super.key});

  @override
  ConsumerState<PosterWallPage> createState() => _PosterWallPageState();
}

class _PosterWallPageState extends ConsumerState<PosterWallPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Channel>>(
        future: ref.read(channelRepositoryProvider).loadBundled(),
        builder: (context, snapshot) {
          final channels = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: _buildHeroBanner()),
              SliverToBoxAdapter(child: _buildCategoryRow()),
              if (channels.isNotEmpty)
                SliverToBoxAdapter(child: _buildLiveSection(channels)),
              SliverToBoxAdapter(
                child: _buildSection('今日推荐', kMockRecommended),
              ),
              SliverToBoxAdapter(child: _buildHotSeries()),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          );
        },
      ),
    );
  }

  // ── 搜索栏 (参考图: 筛选 + 历史) ──
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            // 搜索框
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/search'),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 18, color: Color(0xFF999999)),
                      SizedBox(width: 6),
                      Text('搜索电影、电视剧、综艺、动漫',
                          style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.filter_list, size: 22, color: IptvColors.textSecondary),
            const SizedBox(width: 8),
            Icon(Icons.history, size: 22, color: IptvColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ── 横幅轮播 ──
  Widget _buildHeroBanner() {
    return SizedBox(
      height: 180,
      child: _HeroBanner(movies: kMockMovies),
    );
  }

  // ── 分类图标 ──
  Widget _buildCategoryRow() {
    const items = [
      ('电视直播', Icons.tv, 0xFFE53935),
      ('电影', Icons.movie, 0xFFFF6F00),
      ('电视剧', Icons.live_tv, 0xFF2E7D32),
      ('综艺', Icons.star, 0xFF1565C0),
      ('动漫', Icons.emoji_emotions, 0xFF6A1B9A),
      ('纪录片', Icons.public, 0xFF00838F),
      ('体育', Icons.sports_soccer, 0xFF0D47A1),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((c) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(c.$3).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Icon(c.$2, color: Color(c.$3), size: 24),
                    // "直播中" 徽章
                    if (c.$1 == '电视直播')
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('直播',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(c.$1,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF333333))),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── 电视直播 (参考图: 左大预览 + 右频道列表) ──
  Widget _buildLiveSection(List<Channel> channels) {
    final cctvs = channels.where((c) => c.categories.contains('央视')).toList();
    final previewCh = cctvs.isNotEmpty ? cctvs.first : channels.first;

    // EPG 节目映射
    final epgPrograms = <String, String>{
      'CCTV-1': '新闻联播',
      'CCTV-5': '体育新闻',
      '湖南卫视': '中餐厅 第八季',
      '东方卫视': '今晚开放麦',
    };
    final epgTimes = <String, String>{
      'CCTV-1': '19:00-19:35',
      'CCTV-5': '18:00-19:00',
      '湖南卫视': '19:30-22:00',
      '东方卫视': '20:20-22:30',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              const Text('电视直播',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/category/cctv'),
                child: Row(children: [
                  Text('更多频道',
                      style: TextStyle(
                          fontSize: 12, color: IptvColors.textSecondary)),
                  Icon(Icons.chevron_right,
                      size: 16, color: IptvColors.textSecondary),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 左大预览 + 右频道列表
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // 左侧: 大预览卡
                Expanded(
                  flex: 3,
                  child: _buildLivePreview(previewCh),
                ),
                const SizedBox(width: 10),
                // 右侧: 频道列表
                Expanded(
                  flex: 2,
                  child: Column(
                    children: cctvs.take(3).toList().asMap().entries.map((e) {
                      final ch = e.value;
                      final displayName = ch.displayName;
                      final program = epgPrograms[displayName] ?? '直播中';
                      final timeSlot = epgTimes[displayName] ?? '';
                      return _buildLiveListItem(ch, program, timeSlot);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview(Channel ch) {
    final hue = (ch.displayName.codeUnitAt(0) * 47 + 120) % 360;
    return GestureDetector(
      onTap: () => context.go('/player/${ch.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.55).toColor(),
          borderRadius: BorderRadius.circular(10),
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1596526131657-ef5e24d3bb41?w=400&h=300&fit=crop',
            ),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 频道标识
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('CCTV-1 综合',
                    style:
                        TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
            // 底部内容
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('新闻联播',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // 进度条
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('19:00-19:35',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveListItem(Channel ch, String program, String timeSlot) {
    return GestureDetector(
      onTap: () => context.go('/player/${ch.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E0D4)),
        ),
        child: Row(
          children: [
            // 频道图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  ch.displayName.length > 6
                      ? ch.displayName.substring(0, 4)
                      : ch.displayName,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 节目信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(program,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333))),
                  const SizedBox(height: 2),
                  Text(timeSlot,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF999999))),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.10),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('直播中',
                  style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 通用海报区块 ──
  Widget _buildSection(String title, List<Content> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const Spacer(),
              GestureDetector(
                child: Row(children: [
                  Text('更多',
                      style: TextStyle(
                          fontSize: 12, color: IptvColors.textSecondary)),
                  Icon(Icons.chevron_right,
                      size: 16, color: IptvColors.textSecondary),
                ]),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _PosterCard(content: items[i], index: i),
          ),
        ),
      ],
    );
  }

  // ── 热播剧集 ──
  Widget _buildHotSeries() {
    const filterTabs = ['全部', '古装', '都市', '悬疑', '喜剧', '动作'];
    const colCount = 3;
    final items = kMockSeries;
    final rows = (items.length / colCount).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              const Text('热播剧集',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const Spacer(),
              GestureDetector(
                child: Row(children: [
                  Text('更多',
                      style: TextStyle(
                          fontSize: 12, color: IptvColors.textSecondary)),
                  Icon(Icons.chevron_right,
                      size: 16, color: IptvColors.textSecondary),
                ]),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filterTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: i == 0
                    ? const Color(0xFFE53935)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(filterTabs[i],
                  style: TextStyle(
                      fontSize: 13,
                      color: i == 0
                          ? Colors.white
                          : const Color(0xFF666666),
                      fontWeight:
                          i == 0 ? FontWeight.w600 : FontWeight.w400)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(rows, (row) {
              final start = row * colCount;
              final end = min(start + colCount, items.length);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: List.generate(end - start, (col) {
                    final idx = start + col;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: col == 0 ? 0 : 6,
                            right: col == colCount - 1 ? 0 : 6),
                        child: _HotSeriesCard(content: items[idx]),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 子组件
// ═══════════════════════════════════════════

// ── Hero 轮播 ──
final _bannerImages = [
  'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800&h=400&fit=crop',
  'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&h=400&fit=crop',
  'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=800&h=400&fit=crop',
  'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&h=400&fit=crop',
  'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963e?w=800&h=400&fit=crop',
];

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
      height: 180,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  _heroCard(items[i], _bannerImages[i % _bannerImages.length]),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _page == i
                      ? const Color(0xFFE53935)
                      : const Color(0xFFD0D0D0),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(Content movie, String imageUrl) {
    final hue = (movie.title.codeUnitAt(0) * 47 + 120) % 360;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          HSLColor.fromAHSL(
                                  1, hue.toDouble(), 0.55, 0.55)
                              .toColor(),
                          HSLColor.fromAHSL(1, (hue + 40) % 360, 0.50,
                                  0.22)
                              .toColor(),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSLColor.fromAHSL(
                                1, hue.toDouble(), 0.55, 0.55)
                            .toColor(),
                        HSLColor.fromAHSL(
                                1, (hue + 40) % 360, 0.50, 0.22)
                            .toColor(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 独播标签
          Positioned(
            top: 10,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('全网独播',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          Positioned(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie.title,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              blurRadius: 4,
                              color: Colors.black38,
                              offset: Offset(0, 1))
                        ])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (movie.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: movie.rating! >= 9.0
                              ? const Color(0xFFE65100)
                              : Colors.black45,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Color(0xFFFFD600)),
                            const SizedBox(width: 2),
                            Text(movie.displayRating,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('立即播放',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 海报收藏卡 ──
final _posterImages = [
  'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=200&h=280&fit=crop',
  'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=200&h=280&fit=crop',
  'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=200&h=280&fit=crop',
  'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=200&h=280&fit=crop',
  'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=200&h=280&fit=crop',
  'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963e?w=200&h=280&fit=crop',
  'https://images.unsplash.com/photo-1500462918059-b1a0cb512f1d?w=200&h=280&fit=crop',
  'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=200&h=280&fit=crop',
];

class _PosterCard extends StatelessWidget {
  final Content content;
  final int index;
  const _PosterCard({required this.content, required this.index});

  @override
  Widget build(BuildContext context) {
    final imgUrl = _posterImages[index % _posterImages.length];
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _gradientFallback(content.title, 0.55),
                    ),
                  ),
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
                  if (content.rating != null && content.rating! >= 9.0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('VIP',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding:
                          const EdgeInsets.fromLTRB(6, 20, 6, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Text(
                        content.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (content.year != null || content.subtitle != null)
            Text(
              content.subtitle ?? content.year ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 10, color: Color(0xFF999999)),
            ),
        ],
      ),
    );
  }
}

// ── 热播剧集海报 ──
class _HotSeriesCard extends StatelessWidget {
  final Content content;
  const _HotSeriesCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final hue = (content.title.codeUnitAt(0) * 47 + 120) % 360;
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.55)
                        .toColor(),
                    HSLColor.fromAHSL(1, (hue + 45) % 360, 0.50, 0.35)
                        .toColor(),
                  ],
                ),
              ),
              child: Center(
                child: Text(content.title.characters.first,
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white30)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(content.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          if (content.rating != null)
            Row(
              children: [
                const Icon(Icons.star,
                    size: 10, color: Color(0xFFFFD600)),
                const SizedBox(width: 2),
                Text(content.displayRating,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF999999))),
              ],
            ),
        ],
      ),
    );
  }
}

// ── 渐变色 fallback ──
Widget _gradientFallback(String title, double lightness) {
  final hue = (title.codeUnitAt(0) * 47 + 120) % 360;
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          HSLColor.fromAHSL(1, hue.toDouble(), 0.55, lightness).toColor(),
          HSLColor.fromAHSL(1, (hue + 45) % 360, 0.50, lightness * 0.7)
              .toColor(),
        ],
      ),
    ),
  );
}