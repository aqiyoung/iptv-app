import 'package:flutter/material.dart';

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
      appBarTheme: const AppBarTheme(
        backgroundColor: IptvColors.bgParchment,
        foregroundColor: IptvColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: IptvTypography.serifTitle,
      ),
      dividerColor: IptvColors.dividerWarm,
    );
  }
}
