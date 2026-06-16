import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 启动恢复服务 — 保存/恢复上次观看的频道
class StartupService {
  static const String _keyLastChannelId = 'last_channel_id';

  /// 保存上次观看的频道 ID
  Future<void> saveLastChannel(String channelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastChannelId, channelId);
    } catch (_) {
      // 写入失败不影响功能
    }
  }

  /// 读取上次观看的频道 ID
  Future<String?> loadLastChannel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastChannelId);
    } catch (_) {
      return null;
    }
  }

  /// 清除记录
  Future<void> clearLastChannel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastChannelId);
    } catch (_) {}
  }
}

/// Riverpod provider
final startupServiceProvider = Provider<StartupService>(
  (ref) => StartupService(),
);
