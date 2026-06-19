// v0.3.7+50 (6/19): 播放页状态栏/导航栏 brightness 逻辑 — 纯函数, 给
// [PlayerPage] 用, 也给 test/ 调 (避免 pump 整页 widget tree).

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 状态栏/导航栏图标亮度跟主题走 — 浅色主题深图标, 暗色主题白图标.
@visibleForTesting
SystemUiOverlayStyle buildSystemUiOverlayForPlayer(
  ColorScheme scheme,
  Brightness brightness,
) {
  final isDark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: scheme.surfaceContainer,
    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
  );
}

/// 退出播放页时还原全 APP 默认 (跟 player 同逻辑).
@visibleForTesting
SystemUiOverlayStyle buildSystemUiOverlayForApp(
  ColorScheme scheme,
  Brightness brightness,
) {
  return buildSystemUiOverlayForPlayer(scheme, brightness);
}
