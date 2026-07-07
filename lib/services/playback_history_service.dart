import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackHistoryEntry {
  final String url;
  final String title;
  final String? posterUrl;
  final DateTime playedAt;

  PlaybackHistoryEntry({
    required this.url,
    required this.title,
    this.posterUrl,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'poster_url': posterUrl,
        'played_at': playedAt.toIso8601String(),
      };

  factory PlaybackHistoryEntry.fromJson(Map<String, dynamic> json) =>
      PlaybackHistoryEntry(
        url: json['url'] as String,
        title: json['title'] as String,
        posterUrl: json['poster_url'] as String?,
        playedAt: DateTime.parse(json['played_at'] as String),
      );
}

class PlaybackHistoryService {
  static const _key = 'playback_history';
  static const _maxItems = 100;

  static Future<List<PlaybackHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PlaybackHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> record({
    required String url,
    required String title,
    String? posterUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.removeWhere((e) => e.url == url);
    list.insert(
      0,
      PlaybackHistoryEntry(url: url, title: title, posterUrl: posterUrl, playedAt: DateTime.now()),
    );
    while (list.length > _maxItems) list.removeLast();
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
