import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/content.dart';
import '../../services/vod_api_service.dart';

/// VOD API 服务单例
final vodApiServiceProvider = Provider<VodApiService>((ref) {
  final service = VodApiService(client: http.Client());
  ref.onDispose(() => service.dispose());
  return service;
});

/// 分类 ID 常量
const _typeIdMovie = 20;      // 电影 (type_id=20 是 API 实际分类, 1 不存在)
const _typeIdSeries = 30;     // 电视剧 (包含国产剧/欧美剧/日韩剧等)
const _typeIdVariety = 45;    // 综艺片
const _typeIdAnime = 39;      // 动漫

/// 推荐内容: 混合分类的最新更新
final vodRecommendedProvider = FutureProvider<List<Content>>((ref) async {
  final api = ref.read(vodApiServiceProvider);
  // 从多个分类取最新内容混合推荐
  final futures = [
    api.getList(typeId: _typeIdMovie, page: 1, pageSize: 5),
    api.getList(typeId: _typeIdSeries, page: 1, pageSize: 3),
    api.getList(typeId: _typeIdVariety, page: 1, pageSize: 2),
  ];
  final results = await Future.wait(futures);
  // 去重 (按 vod_id)
  final seen = <int>{};
  final merged = <Map<String, dynamic>>[];
  for (final list in results) {
    for (final item in list) {
      final id = item['vod_id'] as int? ?? 0;
      if (id > 0 && seen.add(id)) merged.add(item);
    }
  }
  // 批量取详情 (拿海报和播放 URL)
  final ids = merged.map((e) => e['vod_id'] as int).toList();
  final details = await api.getDetail(ids.take(10).toList());
  return details.map((d) => api.toContent(d)).toList();
});

/// 热播电影
final vodMoviesProvider = FutureProvider<List<Content>>((ref) async {
  final api = ref.read(vodApiServiceProvider);
  final items = await api.getList(typeId: _typeIdMovie, page: 1, pageSize: 10);
  final ids = items.map((e) => e['vod_id'] as int).toList();
  final details = await api.getDetail(ids);
  return details.map((d) => api.toContent(d)).toList();
});

/// 热播剧集
final vodSeriesProvider = FutureProvider<List<Content>>((ref) async {
  final api = ref.read(vodApiServiceProvider);
  final items = await api.getList(typeId: _typeIdSeries, page: 1, pageSize: 10);
  final ids = items.map((e) => e['vod_id'] as int).toList();
  final details = await api.getDetail(ids);
  return details.map((d) => api.toContent(d)).toList();
});

/// 热门综艺
final vodVarietyProvider = FutureProvider<List<Content>>((ref) async {
  final api = ref.read(vodApiServiceProvider);
  final items = await api.getList(typeId: _typeIdVariety, page: 1, pageSize: 8);
  final ids = items.map((e) => e['vod_id'] as int).toList();
  final details = await api.getDetail(ids);
  return details.map((d) => api.toContent(d)).toList();
});