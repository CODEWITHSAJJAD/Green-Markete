part of 'app_database.dart';

class CacheDao extends _BaseDao {
  CacheDao(AppDatabase db) : super(db);

  Future<void> cache(String key, String value, String entityType, {Duration? ttl}) async {
    await into(attachedDatabase.cacheEntries).insertOnConflictUpdate(
      CacheEntriesCompanion(
        key: Value(key),
        value: Value(value),
        entityType: Value(entityType),
        createdAt: Value(DateTime.now()),
        expiresAt: Value(ttl != null ? DateTime.now().add(ttl) : null),
      ),
    );
  }

  Future<String?> get(String key, String entityType) async {
    final row = await (select(attachedDatabase.cacheEntries)
          ..where((t) => t.key.equals(key) & t.entityType.equals(entityType)))
        .getSingleOrNull();

    if (row == null) return null;
    if (row.expiresAt != null && row.expiresAt!.isBefore(DateTime.now())) {
      await (delete(attachedDatabase.cacheEntries)
            ..where((t) => t.key.equals(key) & t.entityType.equals(entityType)))
          .go();
      return null;
    }
    return row.value;
  }

  Future<void> evict(String key, String entityType) async {
    await (delete(attachedDatabase.cacheEntries)
          ..where((t) => t.key.equals(key) & t.entityType.equals(entityType)))
        .go();
  }

  Future<void> evictByType(String entityType) async {
    await (delete(attachedDatabase.cacheEntries)
          ..where((t) => t.entityType.equals(entityType)))
        .go();
  }

  Future<void> clearAll() async {
    await delete(attachedDatabase.cacheEntries).go();
  }
}
