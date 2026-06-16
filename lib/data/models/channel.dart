import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel.freezed.dart';
part 'channel.g.dart';

/// iptv-org 频道模型
/// Schema: https://iptv-org.github.io/api/channels.json
@freezed
class Channel with _$Channel {
  const factory Channel({
    /// iptv-org stable id, e.g. "CCTV1.cn"
    required String id,

    /// 显示名（英文/罗马字）
    required String name,

    /// 国家 ISO 3166-1 alpha-2, e.g. "CN"
    required String country,

    /// 主分类（取第一个）
    @Default(<String>[]) List<String> categories,

    /// Logo URL (从 logos.json 关联)
    String? logoUrl,

    /// 可用播放源（从 streams.json 关联）
    @Default(<String>[]) List<String> sources,

    /// 替代名（多语言），如 ["CCTV-1", "央视一套"]
    @Default(<String>[]) List<String> altNames,
  }) = _Channel;

  factory Channel.fromJson(Map<String, dynamic> json) =>
      _$ChannelFromJson(json);
}
