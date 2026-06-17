import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'typography.dart';

class IptvTheme {
  IptvTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: IptvColors.accentTerracotta,
        primary: IptvColors.accentTerracotta,
        surface: IptvColors.bgParchment,
        onSurface: IptvColors.textPrimary,
        secondary: IptvColors.accentClay,
      ),
      scaffoldBackgroundColor: IptvColors.bgParchment,
      textTheme: const TextTheme(
        headlineLarge: IptvTypography.serifHeadline,
        titleLarge: IptvTypography.serifTitle,
        titleMedium: IptvTypography.sansTitle,
        bodyLarge: IptvTypography.body,
        bodyMedium: IptvTypography.body,
        labelSmall: IptvTypography.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: IptvColors.bgParchment,
        foregroundColor: IptvColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: IptvTypography.serifTitle,
        // 6/17 (UI 优化): 顶层 AppBar 状态栏用黑图标 (跟浅米色页面背景配套)
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: IptvColors.bgParchment,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      dividerColor: IptvColors.dividerWarm,
    );
  }
}
