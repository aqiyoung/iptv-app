import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 启动恢复服务 — 保存/恢复上次观看的频道
class StartupService {
  /// 抽象的存储层 — test 可注入 [InMemoryStartupStore] 避免 SharedPreferences
  /// 默认实现用 SharedPreferences (生产环境)
  ///
  /// prefsLoader 可空 (允许传 null 表示用默认). 默认是
  /// SharedPreferences.getInstance (返回 Future<SharedPreferences>, 非空).
  StartupService({Future<SharedPreferences> Function()? prefsLoader})
      : _prefsLoader = prefsLoader;

  static Future<SharedPreferences> _defaultPrefsLoader() =>
      SharedPreferences.getInstance();

  final Future<SharedPreferences> Function()? _prefsLoader;

  SharedPreferences? _prefs;
  Future<SharedPreferences> _getPrefs() async {
    final loader = _prefsLoader ?? _defaultPrefsLoader;
    return _prefs ??= await loader();
  }

  static const String _keyLastChannelId = 'last_channel_id';

  /// 保存上次观看的频道 ID
  Future<void> saveLastChannel(String channelId) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyLastChannelId, channelId);
    } catch (e) {
      debugPrint('StartupService.saveLastChannel failed: $e');
    }
  }

  /// 读取上次观看的频道 ID
  Future<String?> loadLastChannel() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_keyLastChannelId);
    } catch (e) {
      debugPrint('StartupService.loadLastChannel failed: $e');
      return null;
    }
  }

  /// 清除记录
  Future<void> clearLastChannel() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyLastChannelId);
    } catch (e) {
      debugPrint('StartupService.clearLastChannel failed: $e');
    }
  }
}

/// Riverpod provider
final startupServiceProvider = Provider<StartupService>(
  (ref) => StartupService(),
);
