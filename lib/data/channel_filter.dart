import 'models/channel.dart';

/// Shared channel filter logic for category classification
class ChannelFilter {
  ChannelFilter._();

  static List<Channel> cctv(List<Channel> all) {
    return all
        .where((c) => c.id.startsWith(RegExp(r'CCTV', caseSensitive: false)))
        .toList();
  }

  static List<Channel> satellite(List<Channel> all) {
    const patterns = ['SatelliteTV', 'TVInternational'];
    return all.where((c) {
      for (final p in patterns) {
        if (c.id.contains(p)) return true;
      }
      return false;
    }).toList();
  }

  static List<Channel> local(List<Channel> all) {
    final sat = satellite(all).map((e) => e.id).toSet();
    final cctvIds = cctv(all).map((e) => e.id).toSet();
    return all
        .where((c) => !sat.contains(c.id) && !cctvIds.contains(c.id))
        .toList();
  }
}
