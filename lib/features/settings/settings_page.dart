// 0.3.6+19 设置页.
//
// 一个 ListTile "主题" → 弹出 RadioListTile 选 系统 / 浅色 / 深色.
// 复用 theme_provider, 切换后立即持久化 (SharedPreferences),
// main.dart 的 ConsumerWidget 监听 themeModeProvider 同步给 MaterialApp.themeMode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// v0.3.7.2 (6/19): 不再 import main.dart (主 dart 写死 const 没用),  用 Provider 读运行时版本号.
import '../../services/version_checker.dart' show currentVersionStringProvider, currentVersionCodeProvider;
import '../../core/theme/colors.dart' show IptvColors;
import 'theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        // v0.3.7+69 (6/19): AppBar title 加显式 textPrimary (跟 AppBarTheme
        // foregroundColor 一致,  但 v0.3.7+60 typography.dart 删了 const TextStyle
        // 的 color 字段,  导致 serifTitle 没 color → const Text('设置') 走
        // DefaultTextStyle → bodyMedium.color,  浅色下 #2A2520 在 #F5F4ED 上
        // 老板反馈 "浅色模式下设置页的设置字看不清").
        title: Text('设置', style: TextStyle(color: IptvColors.textPrimary)),
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
            title: const Text('主题', style: TextStyle(color: IptvColors.textPrimary)),
            subtitle: Text(_modeLabel(mode), style: const TextStyle(color: IptvColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref, current: mode),
          ),
          Divider(height: 0.5, thickness: 0.5, color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),),
          Consumer(
            builder: (context, ref, _) {
              // v0.3.7.2 (6/19): 运行时从 Provider 读真实版本号.
              // 之前 const '0.3.5+37' 从 v0.3.5+37 后一直没改过.
              final version = ref.watch(currentVersionStringProvider);
              final code = ref.watch(currentVersionCodeProvider);
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本号', style: TextStyle(color: IptvColors.textPrimary)),
                subtitle: Text('$version (build $code)', style: const TextStyle(color: IptvColors.textSecondary)),
              );
            },
          ),
          Divider(height: 0.5, thickness: 0.5, color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),),
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
