/// VOD Riverpod 状态管理

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tvbox_config.dart';
import 'mac_cms_service.dart';

// ============= TVBox 配置管理 =============

/// 已加载的 TVBox 配置
class TVBoxConfigState {
  final TVBoxConfig? config;
  final String? configUrl;
  final bool loading;
  final String? error;

  const TVBoxConfigState({
    this.config,
    this.configUrl,
    this.loading = false,
    this.error,
  });

  TVBoxConfigState copyWith({
    TVBoxConfig? config,
    String? configUrl,
    bool? loading,
    String? error,
  }) {
    return TVBoxConfigState(
      config: config ?? this.config,
      configUrl: configUrl ?? this.configUrl,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  /// 获取 MacCMS API 服务列表
  List<MacCMSService> get services {
    if (config == null) return [];
    return config!.macCMSSites.map((site) => MacCMSService(site.api)).toList();
  }

  /// 获取站点列表（含名字）
  List<_ServiceWithName> get namedServices {
    if (config == null) return [];
    return config!.macCMSSites
        .map((site) => _ServiceWithName(name: site.name, service: MacCMSService(site.api)))
        .toList();
  }
}

class _ServiceWithName {
  final String name;
  final MacCMSService service;
  const _ServiceWithName({required this.name, required this.service});
}

/// TVBox 配置 Provider
class TVBoxConfigNotifier extends StateNotifier<TVBoxConfigState> {
  TVBoxConfigNotifier() : super(const TVBoxConfigState());

  /// 从 URL 加载 TVBox 配置
  Future<void> load(String url) async {
    if (state.configUrl == url && state.config != null) return;
    state = state.copyWith(loading: true, error: null, configUrl: url);
    try {
      final config = await TVBoxConfig.fetch(url);
      state = state.copyWith(config: config, loading: false);
      // 保存到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vod_config_url', url);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// 从本地恢复配置 URL
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('vod_config_url');
    if (url != null && url.isNotEmpty) {
      await load(url);
    }
  }
}

final tvboxConfigProvider = StateNotifierProvider<TVBoxConfigNotifier, TVBoxConfigState>(
  (ref) => TVBoxConfigNotifier(),
);

// ============= VOD 内容 =============

/// VOD 首页内容（合并多个 MacCMS API 结果）
class VODHomeState {
  final List<VODItem> items;
  final bool loading;
  final String? error;

  const VODHomeState({
    this.items = const [],
    this.loading = false,
    this.error,
  });
}

final vodHomeProvider = FutureProvider.autoDispose<List<VODItem>>((ref) async {
  final configState = ref.watch(tvboxConfigProvider);
  final services = configState.services;

  if (services.isEmpty) return [];

  // 并行请求所有可用的 MacCMS API
  final results = await Future.wait(
    services.map((s) => s.home().catchError((_) => <VODItem>[])),
    eagerError: false,
  );

  // 合并去重（同名去重）
  final seen = <String>{};
  return results.expand((list) => list).where((item) {
    if (item.name.isEmpty) return false;
    if (seen.contains(item.name)) return false;
    seen.add(item.name);
    return true;
  }).take(100).toList();
});

/// VOD 搜索结果
final vodSearchProvider = FutureProvider.autoDispose.family<List<VODItem>, String>(
  (ref, keyword) async {
    if (keyword.isEmpty) return [];
    final configState = ref.watch(tvboxConfigProvider);
    final services = configState.services;

    final results = await Future.wait(
      services.map((s) => s.search(keyword).then((r) => r.list).catchError((_) => <VODItem>[])),
      eagerError: false,
    );

    final seen = <String>{};
    return results.expand((list) => list).where((item) {
      if (item.name.isEmpty) return false;
      if (seen.contains(item.name)) return false;
      seen.add(item.name);
      return true;
    }).take(50).toList();
  },
);