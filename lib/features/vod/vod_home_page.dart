/// VOD 首页 - 影视点播主页
///
/// 显示已加载的 TVBox 源和视频推荐列表

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/vod/vod_providers.dart';
import '../../data/vod/mac_cms_service.dart';
import '../../core/theme/colors.dart';
import 'tvbox_config_page.dart';

class VODHomePage extends ConsumerStatefulWidget {
  const VODHomePage({super.key});

  @override
  ConsumerState<VODHomePage> createState() => _VODHomePageState();
}

class _VODHomePageState extends ConsumerState<VODHomePage> {
  @override
  void initState() {
    super.initState();
    // 启动时恢复之前保存的配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tvboxConfigProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(tvboxConfigProvider);
    final homeVideos = ref.watch(vodHomeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部标题栏
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      '影视点播',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    // 搜索按钮
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Color(0xFF9E9E9E)),
                      onPressed: () => _showSearch(context, ref),
                    ),
                    // 配置按钮
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Color(0xFF9E9E9E)),
                      onPressed: () => context.push('/vod/config'),
                    ),
                  ],
                ),
              ),
            ),

            // 配置状态栏
            SliverToBoxAdapter(
              child: _ConfigStatusBar(configState: configState),
            ),

            // 站点列表
            if (configState.config != null && configState.config!.macCMSSites.isNotEmpty)
              SliverToBoxAdapter(
                child: _SiteChips(sites: configState.config!.macCMSSites),
              ),

            // 视频推荐列表
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '热门推荐',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            homeVideos.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFF9E9E9E), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '加载失败\n${e.toString()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_outlined, color: Color(0xFF3A3A3A), size: 64),
                          SizedBox(height: 12),
                          Text(
                            '暂无视频\n请先配置 TVBox 视频源',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF6E6E6E), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // 网格布局
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.67,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _VODGridItem(item: items[index]),
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(
      context: context,
      delegate: _VODSearchDelegate(ref: ref),
    );
  }
}

/// 配置状态栏
class _ConfigStatusBar extends ConsumerWidget {
  final TVBoxConfigState configState;

  const _ConfigStatusBar({required this.configState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (configState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935))),
            SizedBox(width: 8),
            Text('加载配置中...', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
          ],
        ),
      );
    }
    if (configState.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '配置加载失败: ${configState.error}',
                style: const TextStyle(color: Color(0xFFFFA726), fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    if (configState.config != null) {
      final count = configState.config!.macCMSSites.length;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 16),
            const SizedBox(width: 6),
            Text(
              '$count 个视频源已加载',
              style: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => context.push('/vod/config'),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFFE53935), size: 16),
            SizedBox(width: 6),
            Text('点击配置 TVBox 视频源', style: TextStyle(color: Color(0xFFE53935), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// 站点标签条
class _SiteChips extends StatelessWidget {
  final List<dynamic> sites;

  const _SiteChips({required this.sites});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final site = sites[index];
          final name = site.name ?? site.key ?? '';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              name.replaceAll(RegExp(r'[🌈🔥📺🎰🗑🎬🌕🌑🌠🚀🌟💮🍓🔮📽️🦋🍄]'), '').trim(),
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}

/// 视频网格项
class _VODGridItem extends StatelessWidget {
  final VODItem item;

  const _VODGridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vod/detail', extra: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: const Color(0xFF1A1A1A),
                child: item.pic.isNotEmpty
                    ? Image.network(
                        item.pic,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1A1A1A),
                          child: const Center(
                            child: Icon(Icons.movie_outlined, color: Color(0xFF3A3A3A), size: 32),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.movie_outlined, color: Color(0xFF3A3A3A), size: 32),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 标题
          Text(
            item.name,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // 备注
          if (item.remarks.isNotEmpty)
            Text(
              item.remarks,
              style: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// 搜索委托
class _VODSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  _VODSearchDelegate({required this.ref});

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入关键词搜索', style: TextStyle(color: Color(0xFF6E6E6E))),
      );
    }

    final results = ref.watch(vodSearchProvider(query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
      error: (e, _) => Center(child: Text('搜索失败: $e', style: const TextStyle(color: Color(0xFF9E9E9E)))),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('未找到结果', style: TextStyle(color: Color(0xFF6E6E6E))),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 40,
                  height: 56,
                  color: const Color(0xFF1A1A1A),
                  child: item.pic.isNotEmpty
                      ? Image.network(item.pic, fit: BoxFit.cover)
                      : const Icon(Icons.movie_outlined, color: Color(0xFF3A3A3A), size: 20),
                ),
              ),
              title: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(
                item.remarks.isNotEmpty ? item.remarks : item.year,
                style: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 12),
              ),
              onTap: () => context.push('/vod/detail', extra: item),
            );
          },
        );
      },
    );
  }
}