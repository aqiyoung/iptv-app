import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';

void main() {
  // 卡 5: 拆分 bootstrap, 让 test 可以跳过 native MediaKit 初始化
  // (flutter_test 在 Linux 跑时 libmpv 不可用)
  bootstrap(skipMediaKit: _shouldSkipMediaKit);
}

bool get _shouldSkipMediaKit {
  // dart.vm.arguments 在 flutter_test 中包含 'flutter:test'
  return const bool.fromEnvironment('FLUTTER_TEST') == true;
}

/// 启动 APP, [skipMediaKit]=true 时跳过 media_kit native init (供 test 使用)
/// [forceSkipMediaKit]=true 时也跳 (供设备上不兼容时降级)
void bootstrap({bool skipMediaKit = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 卡 7: 全局错误处理 → logcat 打印 + 红屏 fallback
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack?.toString() ?? '(no stack)');
    debugPrint('=====================');
  };

  // 卡 7: MediaKit 初始化失败降级 (仍可以起 app, 只是 player 打不开)
  if (!skipMediaKit) {
    try {
      await MediaKit.ensureInitialized().timeout(const Duration(seconds: 5));
    } catch (e, st) {
      debugPrint('=== MediaKit init FAILED, 降级启动 ===');
      debugPrint('$e');
      debugPrint('$st');
      // 不 throw, 继续 runApp, 详情页会另报
    }
  }

  runApp(const ProviderScope(child: IptvApp()));
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '三页直播',
      debugShowCheckedModeBanner: false,
      theme: IptvTheme.light(),
      routerConfig: buildRouter(),
      builder: (context, child) =>
          _ErrorBoundary(child: child ?? const SizedBox()),
    );
  }
}

/// 卡 7: 错误边界 — build 过程中抛错时显示报错界面 + 报告给 Riverpod/errorWidget
class _ErrorBoundary extends StatelessWidget {
  const _ErrorBoundary({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder =
        (FlutterErrorDetails details) => _CrashScreen(details: details);
    return child;
  }
}

class _CrashScreen extends StatelessWidget {
  const _CrashScreen({required this.details});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFEBEE),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 12),
              const Text(
                '三页直播 - 启动错误',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB71C1C)),
              ),
              const SizedBox(height: 8),
              const Text(
                'APP 启动时发生错误, 详细信息如下。重启 / 清除缓存 / 重装可能解决。',
                style: TextStyle(fontSize: 13, color: Color(0xFF7F0000)),
              ),
              const SizedBox(height: 16),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF424242)),
              ),
              const SizedBox(height: 12),
              Text(
                details.stack?.toString() ?? '(no stack trace)',
                style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Color(0xFF616161)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
