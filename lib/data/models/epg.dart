/// EPG 节目单条目
class EpgEntry {
  const EpgEntry({
    required this.channelId,
    required this.title,
    required this.start,
    required this.end,
  });

  final String channelId;
  final String title;
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  factory EpgEntry.fromJson(Map<String, dynamic> j) {
    return EpgEntry(
      channelId: (j['channel_id'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      start: DateTime.parse(j['start'] as String),
      end: DateTime.parse(j['end'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel_id': channelId,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };
}
