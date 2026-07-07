import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers/vod_provider.dart';
import '../../../data/models/content.dart';

/// 视界 VOD 分类浏览页 — iQiyi 风格
/// 顶部 Tab 栏（电影/电视剧/综艺）+ 二级分类标签 + 内容横滚
class VodCategoryBrowserPage extends ConsumerStatefulWidget {
  const VodCategoryBrowserPage({super.key, required this.initialTab});

  /// 初始选中的 Tab 索引: 0=电影, 1=电视剧, 2=综艺
  final int initialTab;

  @override
  ConsumerState<VodCategoryBrowserPage> createState() => _VodCategoryBrowserPageState();
}

class _VodCategoryBrowserPageState extends ConsumerState<VodCategoryBrowserPage> {
  late int _selectedTab;
  int _selectedSub = 0;

  static const _tabs = ['电影', '电视剧', '综艺'];

  static const _subCategories = [
    ['全部', '动作', '科幻', '喜剧', '爱情', '悬疑', '动画', '犯罪'],
    ['全部', '国产剧', '欧美剧', '日韩剧', '悬疑', '古装', '都市'],
    ['全部', '真人秀', '选秀', '脱口秀', '访谈', '竞技', '生活'],
  ];

  static const _tabTypeIds = [20, 30, 45];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _selectedTab == 0
        ? vodMoviesProvider
        : _selectedTab == 1
            ? vodSeriesProvider
            : vodVarietyProvider;
    final async = ref.watch(provider);
    final subList = _subCategories[_selectedTab];

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('分类浏览', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Tab 栏 ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = i == _selectedTab;
                return Padding(
                  padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 24 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() { _selectedTab = i; _selectedSub = 0; }),
                    child: Column(
                      children: [
                        Text(
                          _tabs[i],
                          style: TextStyle(
                            color: active ? Colors.white : const Color(0xFF9E9E9E),
                            fontSize: 17,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          // ─── 二级分类标签 ────────────────────────────────────
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: subList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = i == _selectedSub;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSub = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0x22E53935) : const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: active ? const Color(0xFFE53935) : Colors.white.withOpacity(0.04)),
                    ),
                    child: Text(
                      subList[i],
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFFD6D6D6),
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // ─── 内容区 ────────────────────────────────────────────
          Expanded(
            child: SizedBox(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('加载失败', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('暂无内容', style: TextStyle(color: Colors.white54)));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () {
                          if (item.sourceUrls.isNotEmpty) {
                            context.go('/player/vod?url=${Uri.encodeComponent(item.sourceUrls.first)}&title=${Uri.encodeComponent(item.title)}');
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF242424),
                                  borderRadius: BorderRadius.circular(8),
                                  image: item.posterUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(item.posterUrl),
                                          fit: BoxFit.cover,
                                          onError: (_, __) {},
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
