import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/channel.dart';

/// Channel Repository — 从编译时内嵌的 JSON 加载
class ChannelRepository {
  const ChannelRepository();

  Future<List<Channel>> loadBundled() async {
    final raw = await rootBundle.loadString('assets/data/channels_cn.json');
    final list = json.decode(raw) as List;
    return list
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

final channelRepositoryProvider = Provider<ChannelRepository>(
  (ref) => const ChannelRepository(),
);

final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final repo = ref.watch(channelRepositoryProvider);
  return repo.loadBundled();
});
