/// 播放页顶栏 — 返回 + 频道名 + 状态 + 时钟 + 收藏 + 退出全屏.
/// 从 player_page.dart 拆出 (v0.3.6+43).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/channel.dart';
import '../../../features/favorites/favorite_button.dart';
import '../../../services/player_service.dart';

/// 播放页顶栏 — 返回 + 频道名 + 状态 + 时钟 + 收藏 + 退出全屏.
class TopBar extends StatefulWidget {
  const TopBar({
    required this.channel,
    required this.state,
    required this.onBack,
    this.onExitFullscreen,
  });

  final Channel? channel;
  final PlayerState state;
  final VoidCallback onBack;
  // v0.3.5.5 P0 bug fix: 退出全屏按钮 — 永远显示, 不参与 _controlsVisible
  // 3s 隐身.  null = 不渲染 (移动端嵌入布局 / TV 默认布局).
  final VoidCallback? onExitFullscreen;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late Timer _clockTimer;
  String _clockText = _clockNow();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _clockText = _clockNow());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  static String _clockNow() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusText = switch (widget.state.status) {
      PlayerStatus.idle => '准备中',
      PlayerStatus.loading => widget.state.attempt == null
          ? '正在尝试源…'
          : '尝试源 ${widget.state.attempt!.index}/${widget.state.attempt!.total}',
      PlayerStatus.playing => 'LIVE',
      PlayerStatus.error => '播放失败',
    };

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: scheme.onSurface),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.channel?.displayName ?? '加载中…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IptvTypography.serifTitle
                      .copyWith(color: scheme.onSurface, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _StatusDot(status: widget.state.status),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _clockText,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: scheme.onSurface),
            onPressed: () {},
          ),
          if (widget.channel != null) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FavoriteIcon(
                channelId: widget.channel!.id,
                channelName: widget.channel!.name,
                size: 24,
                onChanged: (isFav) {
                  // 收藏状态变化不需要额外动作, sqflite 已持久化
                },
              ),
            ),
          ],
          // v0.3.5.5 P0 bug fix: 退出全屏按钮放在 TopBar 末尾, 永远 visible.
          // (原来在 _buildFullscreenOverlay 里单独 Positioned, 跟 TopBar
          // 走 _controlsVisible 时一起隐 — 用户反馈体验严重 bug.)
          // 跟右下角全屏按钮统一 — 背景 surfaceContainerHigh, 图标
          // onSurface (跟主题联动).
          if (widget.onExitFullscreen != null) ...[
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: IconButton(
                icon: Icon(
                  Icons.fullscreen_exit,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 22,
                ),
                tooltip: '退出全屏',
                onPressed: widget.onExitFullscreen!,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final PlayerStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      PlayerStatus.playing => IptvColors.accentTerracotta,
      PlayerStatus.loading => IptvColors.accentTerracotta.withOpacity(0.7),
      PlayerStatus.error => scheme.error,
      PlayerStatus.idle => scheme.onSurfaceVariant.withOpacity(0.38),
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
