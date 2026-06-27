part of 'app_database.dart';

class SyncQueueDao extends _BaseDao {
  SyncQueueDao(AppDatabase db) : super(db);

  Future<int> enqueue(String operation, String endpoint, String payload) async {
    return into(attachedDatabase.syncQueueEntries).insert(
      SyncQueueEntriesCompanion(
        operation: Value(operation),
        endpoint: Value(endpoint),
        payload: Value(payload),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<SyncQueueEntry>> getPending() async {
    final rows = await (select(attachedDatabase.syncQueueEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
    return rows;
  }

  Future<void> markCompleted(int id) async {
    await (update(attachedDatabase.syncQueueEntries)
          ..where((t) => t.id.equals(id)))
        .write(const SyncQueueEntriesCompanion(status: Value('completed')));
  }

  Future<void> markFailed(int id) async {
    final entry = await (select(attachedDatabase.syncQueueEntries)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final newCount = entry.retryCount + 1;
    final newStatus = newCount >= 5 ? 'failed' : 'pending';
    await (update(attachedDatabase.syncQueueEntries)
          ..where((t) => t.id.equals(id)))
        .write(
      SyncQueueEntriesCompanion(
        retryCount: Value(newCount),
        status: Value(newStatus),
      ),
    );
  }

  Future<void> clearCompleted() async {
    await (delete(attachedDatabase.syncQueueEntries)
          ..where((t) => t.status.equals('completed')))
        .go();
  }

  Future<int> getPendingCount() async {
    final rows = await (select(attachedDatabase.syncQueueEntries)
          ..where((t) => t.status.equals('pending')))
        .get();
    return rows.length;
  }
}
