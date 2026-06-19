// v0.3.7+50 (6/19): 状态栏/导航栏 brightness 跟主题走 — 纯函数测试.
// 不 pump 整页 widget tree, 直接调 buildSystemUiOverlayForPlayer/App
// 验证 light/dark 模式输出.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyelive/features/player/system_ui_overlay.dart';

void main() {
  group('buildSystemUiOverlayForPlayer 跟主题走', () {
    test('浅色主题 → statusBarIconBrightness=dark (深图标)', () {
      const scheme = ColorScheme.light();
      final overlay = buildSystemUiOverlayForPlayer(
        scheme,
        Brightness.light,
      );
      expect(overlay.statusBarIconBrightness, Brightness.dark,
          reason: '浅色主题状态栏图标应该是深的才能看清');
      expect(overlay.statusBarBrightness, Brightness.light,
          reason: 'iOS 端: 状态栏文字应匹配 light 主题');
    });

    test('暗色主题 → statusBarIconBrightness=light (白图标)', () {
      const scheme = ColorScheme.dark();
      final overlay = buildSystemUiOverlayForPlayer(
        scheme,
        Brightness.dark,
      );
      expect(overlay.statusBarIconBrightness, Brightness.light,
          reason: '暗色主题状态栏图标应该是白的才能看清');
      expect(overlay.statusBarBrightness, Brightness.dark,
          reason: 'iOS 端: 状态栏文字应匹配 dark 主题');
    });

    test('statusBarColor 永远透明 (edge-to-edge)', () {
      final lightOverlay = buildSystemUiOverlayForPlayer(
        const ColorScheme.light(),
        Brightness.light,
      );
      final darkOverlay = buildSystemUiOverlayForPlayer(
        const ColorScheme.dark(),
        Brightness.dark,
      );
      expect(lightOverlay.statusBarColor, Colors.transparent);
      expect(darkOverlay.statusBarColor, Colors.transparent);
    });

    test('systemNavigationBarColor 浅色=米色 (v0.3.7+59 显式 IptvColors)', () {
      // v0.3.7+59: 之前用 scheme.surfaceContainer (M3 API 在 ColorScheme.dark() 里
      // 可能未定义变 null,  导航栏变默认黑色扮眼).  改成显式 IptvColors.bgParchment
      // / darkBg,  跟 AppBarTheme 一致.
      const scheme = ColorScheme.light();
      final overlay = buildSystemUiOverlayForPlayer(
        scheme,
        Brightness.light,
      );
      // 浅色主题: 导航栏=米色 bgParchment (0xF5F4ED)
      expect(overlay.systemNavigationBarColor, const Color(0xFFF5F4ED));
    });

    test('systemNavigationBarColor 暗色=深棕 (v0.3.7+59 显式 IptvColors)', () {
      const scheme = ColorScheme.dark();
      final overlay = buildSystemUiOverlayForPlayer(
        scheme,
        Brightness.dark,
      );
      // 暗色主题: 导航栏=深棕 darkBg (0x1A1612)
      expect(overlay.systemNavigationBarColor, const Color(0xFF1A1612));
    });
  });

  group('buildSystemUiOverlayForApp 跟 player 一致', () {
    test('浅色 → 深图标', () {
      const scheme = ColorScheme.light();
      final overlay = buildSystemUiOverlayForApp(scheme, Brightness.light);
      expect(overlay.statusBarIconBrightness, Brightness.dark);
    });

    test('暗色 → 白图标', () {
      const scheme = ColorScheme.dark();
      final overlay = buildSystemUiOverlayForApp(scheme, Brightness.dark);
      expect(overlay.statusBarIconBrightness, Brightness.light);
    });
  });
}
