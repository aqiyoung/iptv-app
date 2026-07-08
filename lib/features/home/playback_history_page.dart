import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../services/playback_history_service.dart';

/// 播放历史记录页
class PlaybackHistoryPage extends StatefulWidget {
  const PlaybackHistoryPage({super.key});

  @override
  State<PlaybackHistoryPage> createState() => _PlaybackHistoryPageState();
}

class _PlaybackHistoryPageState extends State<PlaybackHistoryPage> {
  List<PlaybackHistoryEntry> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await PlaybackHistoryService.load();
    setState(() { _items = items; _loaded = true; });
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('playback_history');
    setState(() => _items = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('播放记录', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: _items.isEmpty
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text('清空记录', style: TextStyle(color: Colors.white)),
                        content: const Text('确定清空所有播放记录？', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
                          TextButton(onPressed: () { Navigator.pop(ctx); _clear(); }, child: const Text('清空', style: TextStyle(color: Color(0xFFE53935)))),
                        ],
                      ),
                    );
                  },
                ),
              ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, color: Colors.white24, size: 56),
                      SizedBox(height: 12),
                      Text('暂无播放记录', style: TextStyle(color: Colors.white38, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E1E1E), height: 1),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                        leading: Container(
                          width: 52,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF242424),
                            borderRadius: BorderRadius.circular(6),
                            image: item.posterUrl != null && item.posterUrl!.isNotEmpty
                                ? DecorationImage(image: NetworkImage(item.posterUrl!), fit: BoxFit.cover, onError: (_, __) {})
                                : null,
                          ),
                        ),
                        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          '${item.playedAt.month.toString().padLeft(2, '0')}-${item.playedAt.day.toString().padLeft(2, '0')} ${item.playedAt.hour.toString().padLeft(2, '0')}:${item.playedAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        onTap: () => context.go('/player/vod?url=${Uri.encodeComponent(item.url)}&title=${Uri.encodeComponent(item.title)}'),
                      );
                    },
                  ),
                ),
    );
  }
}
