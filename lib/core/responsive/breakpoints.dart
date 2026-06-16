import 'package:flutter/widgets.dart';

/// 三档断点 — 手机 / 平板 / TV
/// 设计目标:
///   - 手机 (≤600dp)  : 单列/2 列, 紧凑
///   - 平板 (601-1024dp): 3 列, 居中限宽
///   - TV  (>1024dp) : 5 列, 全宽, 焦点间距大
///
/// 断点参考 Material Design 3:
///   https://m3.material.io/foundations/layout/applying-layout/window-size-classes
class Breakpoints {
  Breakpoints._();

  /// ≤600dp 视为手机
  static const double phone = 600;

  /// 601-1024dp 视为平板
  static const double tablet = 1024;

  /// >1024dp 视为 TV / 桌面 / 横屏盒子
  static const double tv = 1024;

  /// 平板及以上使用的最大内容宽度 (防平板过宽不可读)
  static const double maxContentWidth = 1280;
}

/// 当前屏幕的设备档位
enum DeviceTier { phone, tablet, tv }

extension DeviceTierX on BuildContext {
  /// 当前设备档位 — 来自 MediaQuery.sizeOf 的宽度
  DeviceTier get deviceTier {
    final w = MediaQuery.sizeOf(this).width;
    if (w <= Breakpoints.phone) return DeviceTier.phone;
    if (w <= Breakpoints.tablet) return DeviceTier.tablet;
    return DeviceTier.tv;
  }

  /// 当前屏幕宽度 (逻辑像素, dp)
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// 当前屏幕高度
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// 用于主要内容居中限宽的容器宽度
  double get contentMaxWidth {
    final w = screenWidth;
    return w > Breakpoints.maxContentWidth ? Breakpoints.maxContentWidth : w;
  }
}
