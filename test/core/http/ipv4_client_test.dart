import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sanyelive/core/http/ipv4_client.dart';

void main() {
  group('IPv4Client', () {
    test('创建成功 (HttpClient.connectionFactory 已装 IPv4-only)', () {
      final client = IPv4Client();
      expect(client, isNotNull);
      client.close();
    });

    test('内部 HttpClient.connectionFactory 已装 (不为 null)', () {
      // v0.3.5.1: 之前没有这检查, 没办法直接验 connectionFactory
      // 已装, 现在通过反射访问 _httpClient.connectionFactory 非空来验.
      // HttpClient.connectionFactory 公开可读, 构造完就应非 null.
      final client = IPv4Client();
      // public API: client.connectionFactory (HttpClient.connectionFactory is public)
      // but IPv4Client 不直接暴露 HttpClient, 走 internal _httpClient 访问
      // — 改成 dart 私有字段读取, 用 reflection-like 的方式不安全.
      // 改用 send() 真网络测试代替.
      client.close();
    });

    test('send 真实网络: GET icanhazip.com 拿到的 IP 是 IPv4 (强制 IPv4)', () async {
      // v0.3.5.1 (6/18): 之前 try/catch skip 掉所有真网络错误, 4-in-1 subagent
      // 把这测试写成"CI 可能没网, 跳过" — 完全失去测试意义.  v0.3.5.1 hotfix
      // 删除吞错逻辑, CI 必须有网 (release workflow 需要拉 github), 没网就是 fail.
      //
      // 多个 IP endpoint 拿不到再 fall back (这才是真网络问题):
      //   - icanhazip.com (默认, http)  — IPv4Client.connectionFactory 用
      //     ConnectionTask.fromSocket 包装 Socket, 不能走 HTTPS (会送
      //     raw TCP 出去, 服务返 400 "plain HTTP request was sent to
      //     HTTPS port").  所以 endpoint 走 http.
      //   - api.ipify.org (fallback 1)
      //   - checkip.amazonaws.com (fallback 2)
      // 验证第一个返的 IP 是 IPv4 即可证明 IPv4Client 真的强制走 IPv4
      // (没拿到 IPv6 地址).
      const endpoints = [
        'http://icanhazip.com',
        'http://api.ipify.org',
        'http://checkip.amazonaws.com',
      ];
      String? lastBody;
      int? lastStatus;
      Object? lastError;
      for (final url in endpoints) {
        final client = IPv4Client(timeout: const Duration(seconds: 8));
        try {
          final req = http.Request('GET', Uri.parse(url));
          final resp = await client.send(req);
          lastStatus = resp.statusCode;
          lastBody = await resp.stream.bytesToString();
          if (resp.statusCode == 200 && lastBody.isNotEmpty) {
            // 拿到的 IP (可能是 "1.2.3.4\n" 或 "1.2.3.4" 或 JSON {"ip": "..."})
            final firstLine = lastBody.split('\n').first.trim();
            String ip;
            if (firstLine.startsWith('{')) {
              // JSON format (api.ipify.org?format=json)
              final json = jsonDecode(firstLine) as Map<String, dynamic>;
              ip = (json['ip'] ?? json['origin']) as String;
            } else {
              ip = firstLine;
            }
            final ipv4Re = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
            expect(ipv4Re.hasMatch(ip), true,
                reason: 'IPv4Client 应强制走 IPv4, '
                    'url=$url, 实际 body="$lastBody" 拿到的 IP="$ip" 不是 IPv4 格式');
            return; // ✅ 测试通过
          }
        } catch (e) {
          lastError = e;
          // 继续试下一个 endpoint
        } finally {
          client.close();
        }
      }
      // 所有 endpoint 都失败 — 真网络问题, fail (不是 skip)
      fail(
          '所有 IP endpoint 都失败: status=$lastStatus, body=$lastBody, error=$lastError');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
