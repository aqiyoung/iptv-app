// 0.3.6+19 设置页.
//
// 一个 ListTile "主题" → 弹出 RadioListTile 选 系统 / 浅色 / 深色.
// 复用 theme_provider, 切换后立即持久化 (SharedPreferences),
// main.dart 的 ConsumerWidget 监听 themeModeProvider 同步给 MaterialApp.themeMode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';  // v0.3.7.2: 不再 import 写死 const, 用 Provider 读运行时版本号
import '../../services/version_checker.dart' show currentVersionStringProvider, currentVersionCodeProvider;
import 'theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题'),
            subtitle: Text(_modeLabel(mode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref, current: mode),
          ),
          const Divider(),
          Consumer(
            builder: (context, ref, _) {
              // v0.3.7.2 (6/19): 运行时从 Provider 读真实版本号.
              // 之前 const '0.3.5+37' 从 v0.3.5+37 后一直没改过.
              final version = ref.watch(currentVersionStringProvider);
              final code = ref.watch(currentVersionCodeProvider);
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本号'),
                subtitle: Text('$version (build $code)'),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode current,
  }) async {
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('选择主题'),
          children: [
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                title: Text(_modeLabel(mode)),
                value: mode,
                groupValue: current,
                onChanged: (v) => Navigator.of(ctx).pop(v),
              ),
          ],
        );
      },
    );
    if (picked != null && picked != current) {
      await ref.read(themeModeProvider.notifier).setMode(picked);
    }
  }

  static String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }
}
