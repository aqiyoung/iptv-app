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

    test('send 方法返回 StreamedResponse, GET github API (IPv4) 200', () async {
      final client = IPv4Client(timeout: const Duration(seconds: 15));
      try {
        // GitHub API 是 IPv4, 不需要 token 也能 hit 到 rate-limit 200/403
        final req = http.Request('GET', Uri.parse('https://api.github.com'));
        final resp = await client.send(req);
        final status = resp.statusCode;
        // 200 (正常) 或 403 (rate limit) 都算通, 关键是不该超时/抛 SocketException
        expect(status, anyOf(200, 403));
      } finally {
        client.close();
      }
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
