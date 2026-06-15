import 'package:flutter/material.dart';

/// Design tokens — 新中式 · 暖色调 · 衬线标题
/// Reference: design doc §5.1
class IptvColors {
  IptvColors._();

  /// 暖米色主背景 — 仿宣纸
  static const Color bgParchment = Color(0xFFF5F4ED);

  /// 卡片背景（略白）
  static const Color bgElevated = Color(0xFFFFFCF6);

  /// 主色 — 赤陶 Terracotta
  static const Color accentTerracotta = Color(0xFFC96442);

  /// 主色深色版 — 紫砂 Clay
  static const Color accentClay = Color(0xFFA85234);

  /// 主文字 — 深棕
  static const Color textPrimary = Color(0xFF2A2520);

  /// 次文字 — 浅棕
  static const Color textSecondary = Color(0xFF6B5F54);

  /// 分隔线 — 暖灰
  static const Color dividerWarm = Color(0xFFE8E0D4);
}
