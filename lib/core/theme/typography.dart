import 'package:flutter/material.dart';

import 'colors.dart';

/// 新中式字体 — 衬线标题 + 系统无衬线正文
/// 衬线：Georgia (iOS/Android 自带，无须打包字体)
class IptvTypography {
  IptvTypography._();

  static const String serifFamily = 'Georgia';
  static const String sansFamily = 'Roboto'; // Android 默认无衬线

  /// 衬线大标题 — 用于 Section 标题
  static const TextStyle serifHeadline = TextStyle(
    fontFamily: serifFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: IptvColors.textPrimary,
  );

  /// 衬线中标题
  static const TextStyle serifTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: IptvColors.textPrimary,
  );

  /// 无衬线小标题
  static const TextStyle sansTitle = TextStyle(
    fontFamily: sansFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: IptvColors.textPrimary,
  );

  /// 正文
  static const TextStyle body = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: IptvColors.textPrimary,
  );

  /// 副文字
  static const TextStyle caption = TextStyle(
    fontFamily: sansFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: IptvColors.textSecondary,
  );
}
