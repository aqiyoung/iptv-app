import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/http/ipv4_client.dart';
import '../models/channel.dart';

/// iptv-org 数据源 — 抓 channels.json
/// API: https://iptv-org.github.io/api/channels.json
class IptvOrgSource {
  IptvOrgSource({http.Client? client, this.endpoint = _defaultEndpoint})
      : _client = client ?? IPv4Client();

  static const String _defaultEndpoint =
      'https://iptv-org.github.io/api/channels.json';

  final http.Client _client;
  final String endpoint;

  /// 拉取所有频道（5万+ 条）。建议只跑一次做离线 build。
  Future<List<Channel>> fetchAll() async {
    final resp = await _client.get(Uri.parse(endpoint));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch iptv-org: HTTP ${resp.statusCode}');
    }
    final list = json.decode(resp.body) as List;
    return list
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  void close() => _client.close();
}
