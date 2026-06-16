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
void bootstrap({bool skipMediaKit = false}) {
  WidgetsFlutterBinding.ensureInitialized();
  if (!skipMediaKit) {
    MediaKit.ensureInitialized();
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
    );
  }
}
