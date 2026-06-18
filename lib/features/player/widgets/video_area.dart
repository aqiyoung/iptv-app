/// 播放页视频区 — media_kit 视频播放 + 加载动画 + 错误 UI.
/// 从 player_page.dart 拆出 (v0.3.6+43).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/channel.dart';
import '../../../services/player_service.dart';
import 'source_picker_sheet.dart';

/// 视频区: media_kit + loading/error overlay.
class VideoArea extends StatelessWidget {
  const VideoArea({
    required this.controller,
    required this.state,
    required this.channel,
  });

  final VideoController controller;
  final PlayerState state;
  final Channel? channel;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      // 6/17 修容器溢出: Wrap AspectRatio 16/9 + Stack in ClipRect, 防止在
      // 某些比例 (e.g. 21:9 曲面屏, iPad 分屏) 上 video widget 算出意外高度
      // 溢出顶/底栏.
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频底层 (黑色)
            ColoredBox(color: Colors.black),
            // media_kit Video (播放时)
            if (state.status == PlayerStatus.playing)
              Video(controller: controller),
            // 加载 / 错误 / 空 占位
            switch (state.status) {
              PlayerStatus.idle || PlayerStatus.loading => LoadingOverlay(
                  text: state.attempt == null
                      ? '正在打开…'
                      : '尝试源 ${state.attempt!.index}/${state.attempt!.total}',
                ),
              PlayerStatus.error =>
                ErrorOverlay(message: state.error ?? '播放失败'),
              PlayerStatus.playing => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}

/// 加载动画 overlay.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.shadow,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  IptvColors.accentTerracotta,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// 错误 UI + 重试/换源按钮.
class ErrorOverlay extends ConsumerWidget {
  const ErrorOverlay({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 6/17 v0.2.3 P0-4: 错误时给用户「重试 + 换源」按钮.
    // current channel 从 currentPlayerStateProvider 拿.  避免外部多传一个
    // channel 参数导致状态不一致.
    final state = ref.watch(currentPlayerStateProvider);
    final channel = state.channel;
    final hasMultipleSources = (channel?.sources.length ?? 0) > 1;

    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.shadow,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: scheme.error,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                '播放失败',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 16),
              // 重试 + 换源 两个按钮.  重试: 重调 play(当前 channel), 走
              // SourceFailover 自动选源.  换源: 弹底部 sheet, 选单源调
              // playSingleSource.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: channel == null
                        ? null
                        : () {
                            ref.read(playerServiceProvider).play(channel);
                          },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onPrimary,
                      side: BorderSide(color: scheme.outline),
                    ),
                  ),
                  if (hasMultipleSources) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: channel == null
                          ? null
                          : () async {
                              final url = await pickSourceUrl(context, channel);
                              if (url == null) return; // 取消
                              ref
                                  .read(playerServiceProvider)
                                  .playSingleSource(url, channel: channel);
                            },
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('换源'),
                      style: FilledButton.styleFrom(
                        backgroundColor: IptvColors.accentTerracotta,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
