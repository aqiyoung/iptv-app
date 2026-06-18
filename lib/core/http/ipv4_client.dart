import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// 强制 IPv4 的 http.Client, 修复 wifi 路由器只支持 IPv4 时连不上的问题.
///
/// Dart 默认 `http.Client()` 用 happy-eyeballs (IPv6 优先 + IPv4 fallback):
/// - 移动数据 (4G/5G): 双栈, 看起来工作
/// - wifi 路由器 (IPv4-only): 解析到 IPv6 地址卡死, 用户"必须连手机流量"
///
/// 通过把 `HttpClient.addresses` 设空列表, 强制走系统默认 IPv4 解析.
class IPv4Client extends http.BaseClient {
  IPv4Client({Duration? timeout})
      : _timeout = timeout ?? const Duration(seconds: 30) {
    _ioClient = IOClient(_createHttpClient());
  }

  final Duration _timeout;
  late final IOClient _ioClient;

  static HttpClient _createHttpClient() {
    final client = HttpClient();
    // 关键: 强制 IPv4 解析 (happy-eyeballs disabled)
    client.addresses = <InternetAddress>[];
    return client;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _ioClient.send(request).timeout(_timeout);
  }

  @override
  void close() {
    _ioClient.close();
    super.close();
  }
}
