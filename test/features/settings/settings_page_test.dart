// v0.3.5.9 设置页版本号显示 — widget 测试
//
// 验收 (proof):
//   1. 设置页显示版本号 (currentVersion)
//   2. 设置页显示 build number (currentVersionCode)
//   3. currentVersion 跟 pubspec 版本一致
//   4. currentVersionCode 是正整数
//   5. 设置页同时有"主题"和"版本号"两个 section

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyelive/features/settings/settings_page.dart';
import 'package:sanyelive/main.dart' show currentVersion, currentVersionCode;

void main() {
  group('SettingsPage 版本号显示 (v0.3.5.9)', () {
    testWidgets('显示版本号 (currentVersion)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsPage()),
        ),
      );

      expect(find.text('版本号'), findsOneWidget);
      expect(find.text(currentVersion), findsOneWidget);
    });

    testWidgets('显示 build number (currentVersionCode)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsPage()),
        ),
      );

      expect(find.text('build $currentVersionCode'), findsOneWidget);
    });

    testWidgets('currentVersion 跟 pubspec 版本一致', (tester) async {
      // pubspec.yaml version: 0.3.5+26
      // main.dart currentVersion 必须匹配
      expect(currentVersion, equals('0.3.5+26'));
    });

    testWidgets('currentVersionCode 是正整数', (tester) async {
      expect(currentVersionCode, greaterThan(0));
      expect(currentVersionCode, equals(26)); // v0.3.5.9 bump +1 from 25
    });

    testWidgets('设置页同时有主题和版本号 section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsPage()),
        ),
      );

      expect(find.text('主题'), findsOneWidget);
      expect(find.text('版本号'), findsOneWidget);
    });
  });
}
