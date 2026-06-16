import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/channel.dart';

/// iptv-org 数据源 — 抓 channels.json + logos.json + streams.json
/// API: https://github.com/iptv-org/api
class IptvOrgSource {
  IptvOrgSource({
    http.Client? client,
    this.channelsEndpoint = _defaultChannelsEndpoint,
    this.logosEndpoint = _defaultLogosEndpoint,
    this.streamsEndpoint = _defaultStreamsEndpoint,
  }) : _client = client ?? http.Client();

  static const String _defaultChannelsEndpoint =
      'https://iptv-org.github.io/api/channels.json';
  static const String _defaultLogosEndpoint =
      'https://iptv-org.github.io/api/logos.json';
  static const String _defaultStreamsEndpoint =
      'https://iptv-org.github.io/api/streams.json';

  final http.Client _client;
  final String channelsEndpoint;
  final String logosEndpoint;
  final String streamsEndpoint;

  /// 拉取所有原始 channels (39k+)
  Future<List<Map<String, dynamic>>> fetchRawChannels() async {
    final resp = await _client.get(Uri.parse(channelsEndpoint));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch iptv-org channels: HTTP ${resp.statusCode}',
      );
    }
    final list = json.decode(resp.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// 拉取所有 logos (id -> url)
  Future<Map<String, String>> fetchLogoMap() async {
    final resp = await _client.get(Uri.parse(logosEndpoint));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch iptv-org logos: HTTP ${resp.statusCode}',
      );
    }
    final list = json.decode(resp.body) as List;
    final out = <String, String>{};
    for (final e in list) {
      final ch = e['channel'] as String?;
      final url = e['url'] as String?;
      if (ch != null && url != null && url.isNotEmpty) {
        out[ch] = url;
      }
    }
    return out;
  }

  /// 拉取所有 streams (channelId -> [urls])
  Future<Map<String, List<String>>> fetchStreamMap() async {
    final resp = await _client.get(Uri.parse(streamsEndpoint));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch iptv-org streams: HTTP ${resp.statusCode}',
      );
    }
    final list = json.decode(resp.body) as List;
    final out = <String, List<String>>{};
    for (final e in list) {
      final ch = e['channel'] as String?;
      final url = e['url'] as String?;
      if (ch == null || url == null || url.isEmpty) continue;
      out.putIfAbsent(ch, () => <String>[]).add(url);
    }
    return out;
  }

  /// 便捷方法: 三次拉取 + 合并成 Channel 列表
  Future<List<Channel>> fetchAll() async {
    final raw = await fetchRawChannels();
    final logos = await fetchLogoMap();
    final streams = await fetchStreamMap();

    return raw.map((j) {
      final id = j['id'] as String;
      return Channel(
        id: id,
        name: (j['name'] as String?) ?? id,
        country: (j['country'] as String?) ?? '',
        categories: (j['categories'] as List?)?.cast<String>() ?? const [],
        logoUrl: logos[id],
        sources: streams[id] ?? const [],
        altNames: (j['alt_names'] as List?)?.cast<String>() ?? const [],
      );
    }).toList(growable: false);
  }

  void close() => _client.close();
}
