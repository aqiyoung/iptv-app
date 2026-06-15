import 'package:flutter/material.dart';

import '../core/theme/typography.dart';

/// 衬线大标题组件 — 章节标题用
class SerifHeadline extends StatelessWidget {
  const SerifHeadline(this.text, {super.key, this.subtitle, this.trailing});

  final String text;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: IptvTypography.serifHeadline),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: IptvTypography.caption),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
