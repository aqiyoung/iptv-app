import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/epg.dart';
import '../../services/epg_service.dart';

/// EPG repository that delegates to EpgService for caching
final epgForChannelProvider =
    FutureProvider.family<List<EpgEntry>, String>((ref, channelId) async {
  final svc = ref.watch(epgServiceProvider);
  return svc.fetch(channelId);
});
