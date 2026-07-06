/// VOD 详情页 - 视频详情 + 播放
///
/// 通过 /vod/detail 路由传入 VODItem extra 参数

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../data/vod/mac_cms_service.dart';
import '../../core/theme/colors.dart';

class VODDetailPage extends ConsumerStatefulWidget {
  final VODItem item;

  const VODDetailPage({super.key, required this.item});

  @override
  ConsumerState<VODDetailPage> createState() => _VODDetailPageState();
}

class _VODDetailPageState extends ConsumerState<VODDetailPage> {
  final Player _player = Player();
  late VideoController _videoController;
  List<PlayEpisode> _episodes = [];
  int _selectedEpisode = 0;
  bool _isPlaying = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _videoController = VideoController(_player);
    _parseEpisodes();
  }

  void _parseEpisodes() {
    setState(() {
      _episodes = widget.item.episodes;
      if (_episodes.isEmpty && widget.item.firstPlayUrl != null) {
        _episodes = [PlayEpisode(name: '播放', url: widget.item.firstPlayUrl!)];
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _playEpisode(int index) {
    if (index >= _episodes.length) return;
    setState(() {
      _selectedEpisode = index;
      _isPlaying = true;
    });
    _player.open(Media(_episodes[index].url));
    _showControlsTemporarily();
  }

  void _togglePlayPause() {
    _player.playOrPause();
  }

  void _showControlsTemporarily() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Column(
          children: [
            // 视频播放区域
            if (_isPlaying) _buildPlayer(),
            // 视频信息
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 标签行
                    Row(
                      children: [
                        if (widget.item.remarks.isNotEmpty)
                          _Tag(text: widget.item.remarks),
                        if (widget.item.year.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _Tag(text: widget.item.year),
                        ],
                        if (widget.item.area.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _Tag(text: widget.item.area),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 简介
                    if (widget.item.content.isNotEmpty) ...[
                      Text(
                        widget.item.content.replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 播放按钮
                    if (!_isPlaying && _episodes.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _playEpisode(0),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('开始播放'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                    // 剧集列表
                    if (_episodes.length > 1) ...[
                      const SizedBox(height: 20),
                      Text(
                        '选集（${_episodes.length}集）',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_episodes.length, (i) {
                          final isSelected = i == _selectedEpisode && _isPlaying;
                          return GestureDetector(
                            onTap: () => _playEpisode(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFE53935) : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFE53935) : Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Text(
                                _episodes[i].name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Video(
              controller: _videoController,
              fill: Colors.black,
            ),
          ),
          // 播放控制覆盖层
          if (_controlsVisible)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Column(
                  children: [
                    // 顶部返回按钮
                    SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              setState(() => _isPlaying = false);
                              _player.stop();
                            },
                          ),
                          const Expanded(
                            child: Text(
                              '正在播放',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 播放/暂停
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _player.state.playing ?? true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
    );
  }
}