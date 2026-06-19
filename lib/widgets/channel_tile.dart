import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../data/models/channel.dart';
import '../features/favorites/favorite_button.dart';

/// 频道整行 tile — 用于频道列表
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.channelNumber,
    required this.channelName,
    this.channel,
    this.country,
    this.isLive = true,
    this.onTap,
  });

  final String channelNumber;
  final String channelName;
  final Channel? channel;
  final String? country;
  final bool isLive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 老板 6/17 需求: 频道名优先用中文, 原名 (英文) 作为副标题.
    // 上层传的 channelName 可能是旧 name, 这里从 channel 重新取
    // displayName + displaySubtitle 兑底.
    final primaryName = channel?.displayName ?? channelName;
    final subtitle = channel?.displaySubtitle;
    // favorite icon 仍然要 iptv org 原名 (作 channelName)
    final favName = channel?.name ?? channelName;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  channelNumber,
                  style: IptvTypography.serifTitle.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryName,
                      style: IptvTypography.sansTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 原名作为副标题 (有差异才显示)
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: IptvTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (country != null && country!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(country!, style: IptvTypography.caption),
                    ],
                  ],
                ),
              ),
              if (channel != null)
                FavoriteIcon(
                  channelId: channel!.id,
                  channelName: favName,
                  size: 20,
                ),
              if (isLive)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
