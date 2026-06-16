import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/channel.dart';

/// "下一频道" 横滑条
///   - 列出当前播放频道之后的 10 个频道 (按列表顺序)
///   - 点击切台 (调用 onChannelTap)
///   - 第一个高亮 "下一频道" 角标
class NextChannelsStrip extends StatelessWidget {
  const NextChannelsStrip({
    super.key,
    required this.currentChannelId,
    required this.allChannels,
    required this.onChannelTap,
    this.max = 10,
  });

  final String currentChannelId;
  final List<Channel> allChannels;
  final void Function(Channel channel) onChannelTap;
  final int max;

  @override
  Widget build(BuildContext context) {
    // 找到当前位置, 之后的频道
    final idx = allChannels.indexWhere((c) => c.id == currentChannelId);
    final after = idx >= 0 ? allChannels.sublist(idx + 1) : const <Channel>[];

    // 如果后续不够 max, 拼上开头的循环 (避免空条)
    final List<Channel> next = [...after];
    var i = 0;
    while (next.length < max && i < allChannels.length) {
      final c = allChannels[i];
      if (c.id != currentChannelId && !next.contains(c)) {
        next.add(c);
      }
      i++;
    }
    final visible = next.take(max).toList();

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            '下一频道',
            style: IptvTypography.caption.copyWith(
              color: IptvColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final ch = visible[i];
              return _ChannelChip(
                channel: ch,
                index: i,
                isNext: i == 0,
                onTap: () => onChannelTap(ch),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.channel,
    required this.index,
    required this.isNext,
    required this.onTap,
  });

  final Channel channel;
  final int index;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 116,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isNext
              ? IptvColors.accentTerracotta.withOpacity(0.12)
              : IptvColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: isNext
              ? Border.all(color: IptvColors.accentTerracotta, width: 1)
              : Border.all(color: IptvColors.dividerWarm, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: IptvTypography.caption.copyWith(
                    color: isNext
                        ? IptvColors.accentTerracotta
                        : IptvColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    channel.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IptvTypography.body.copyWith(
                      fontSize: 13,
                      color: isNext
                          ? IptvColors.textPrimary
                          : IptvColors.textPrimary,
                      fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (channel.sources.isNotEmpty)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: IptvColors.accentTerracotta,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: IptvColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    channel.primaryCategory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IptvTypography.caption.copyWith(
                      color: IptvColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
