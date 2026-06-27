import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local/app_database.dart';
import '../datasources/remote/auth_remote_ds.dart';
import '../../core/network/api_client.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    database: ref.watch(appDatabaseProvider),
    dio: ref.watch(dioProvider),
  );
});

class SyncRepository {
  final AppDatabase _database;
  final Dio _dio;
  bool _isSyncing = false;

  SyncRepository({
    required AppDatabase database,
    required Dio dio,
  })  : _database = database,
        _dio = dio;

  bool get isSyncing => _isSyncing;

  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pending = await _database.syncQueueDao.getPending();
      for (final item in pending) {
        try {
          await _dio.request(
            item.endpoint,
            data: item.payload,
            options: Options(method: item.operation),
          );
          await _database.syncQueueDao.markCompleted(item.id);
        } catch (_) {
          await _database.syncQueueDao.markFailed(item.id);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
