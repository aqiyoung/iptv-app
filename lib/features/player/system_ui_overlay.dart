// v0.3.7+59 (6/19): 播放页状态栏/导航栏 brightness 逻辑 — 纯函数, 给
// [PlayerPage] 用, 也给 test/ 调 (避免 pump 整页 widget tree).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanyelive/core/theme/colors.dart';

/// 状态栏/导航栏图标亮度跟主题走 — 浅色主题深图标, 暗色主题白图标.
/// v0.3.7+59:  systemNavigationBarColor 不用 scheme.surfaceContainer (M3 API 在
/// ColorScheme.dark() 里可能未定义变 null,  底部导航栏会变成默认黑色扮眼).
/// 改成显式 IptvColors.bgParchment / darkBg,  跟 AppBarTheme 一致.
SystemUiOverlayStyle buildSystemUiOverlayForPlayer(
  ColorScheme scheme,
  Brightness brightness,
) {
  final isDark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: isDark
        ? IptvColors.darkBg
        : IptvColors.bgParchment,
    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
  );
}

/// 退出播放页时还原全 APP 默认 (跟 player 同逻辑).
SystemUiOverlayStyle buildSystemUiOverlayForApp(
  ColorScheme scheme,
  Brightness brightness,
) {
  return buildSystemUiOverlayForPlayer(scheme, brightness);
}
