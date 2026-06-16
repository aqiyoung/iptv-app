import 'package:http/http.dart' as http;

import '../models/epg.dart';

/// iptv-org EPG 数据源 (XMLTV, 巨大，卡 3 仅占位)
class EpgSource {
  EpgSource({http.Client? client, this.endpoint = _defaultEndpoint})
      : _client = client ?? http.Client();

  static const String _defaultEndpoint =
      'https://iptv-org.github.io/epg/guides/ar.xml.gz';

  final http.Client _client;
  final String endpoint;

  /// 拉取某个国家/地区 EPG（卡 5 实现 XMLTV 解析）
  Future<List<EpgEntry>> fetchCountry(String cc) async {
    throw UnimplementedError('EPG parsing deferred to card 5');
  }

  void close() => _client.close();
}
