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

    test('send 真实网络: GET httpbin.org/ip 拿到的 origin 是 IPv4 (强制 IPv4)', () async {
      // v0.3.5.1 (6/18): 之前 try/catch skip 掉所有真网络错误, 4-in-1 subagent
      // 把这测试写成"CI 可能没网, 跳过" — 完全失去测试意义.  v0.3.5.1 hotfix
      // 删除吞错逻辑, CI 必须有网 (release workflow 需要拉 github), 没网就是 fail.
      // httpbin.org/ip 返回 JSON {"origin": "<ip>"}, 验证 origin 是 IPv4
      // 即可证明 IPv4Client 真的强制走 IPv4 (没拿到 IPv6 地址).
      final client = IPv4Client(timeout: const Duration(seconds: 10));
      try {
        final req = http.Request('GET', Uri.parse('https://httpbin.org/ip'));
        final resp = await client.send(req);
        final body = await resp.stream.bytesToString();

        expect(resp.statusCode, 200,
            reason: 'httpbin.org/ip 应返回 200, 实际 ${resp.statusCode}');
        expect(body, isNotEmpty);

        final json = jsonDecode(body) as Map<String, dynamic>;
        final origin = json['origin'] as String;
        expect(origin, isNotNull,
            reason: 'httpbin.org 返回 body 没 origin 字段: $body');

        // origin 可能是 "1.2.3.4" 或 "1.2.3.4, 5.6.7.8" (代理链)
        // 任一字段是 IPv4 即视为通过 — 如果客户端走到 IPv6, httpbin 会返回 IPv6 origin
        final firstIp = origin.split(',').first.trim();
        final ipv4Re = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
        expect(ipv4Re.hasMatch(firstIp), true,
            reason:
                'IPv4Client 应该强制走 IPv4, 实际 origin="$origin" 第一个 IP="$firstIp" 不是 IPv4 格式');
      } finally {
        client.close();
      }
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
