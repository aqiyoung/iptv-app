import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// 收藏服务 — sqflite 本地存储
class FavoritesService {
  FavoritesService({Database? db}) : _db = db;

  Database? _db;

  static const String _table = 'favorites';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'iptv_favorites.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            channel_id TEXT PRIMARY KEY,
            channel_name TEXT NOT NULL,
            added_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// 查询所有收藏的频道 ID (按添加时间倒序)
  Future<List<String>> getAll() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'added_at DESC');
    return rows.map((r) => r['channel_id'] as String).toList();
  }

  /// 判断是否已收藏
  Future<bool> isFavorite(String channelId) async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'channel_id = ?',
      whereArgs: [channelId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// 添加收藏
  Future<void> add(String channelId, String channelName) async {
    final db = await database;
    await db.insert(
      _table,
      {
        'channel_id': channelId,
        'channel_name': channelName,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// 移除收藏
  Future<void> remove(String channelId) async {
    final db = await database;
    await db.delete(_table, where: 'channel_id = ?', whereArgs: [channelId]);
  }

  /// 切换收藏状态, 返回切换后的状态 (true=已收藏)
  Future<bool> toggle(String channelId, String channelName) async {
    final fav = await isFavorite(channelId);
    if (fav) {
      await remove(channelId);
      return false;
    } else {
      await add(channelId, channelName);
      return true;
    }
  }
}

/// Riverpod provider
final favoritesServiceProvider = Provider<FavoritesService>(
  (ref) => FavoritesService(),
);

/// 收藏列表 provider (刷新用)
final favoritesProvider = FutureProvider<List<String>>((ref) async {
  final svc = ref.watch(favoritesServiceProvider);
  return svc.getAll();
});
