import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/epg.dart';
import '../sources/epg_source.dart';

final epgSourceProvider = Provider<EpgSource>((ref) => EpgSource());

final epgForChannelProvider =
    FutureProvider.family<List<EpgEntry>, String>((ref, channelId) async {
  return const [];
});
