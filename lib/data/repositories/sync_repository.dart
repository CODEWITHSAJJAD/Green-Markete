class SyncRepository {
  final bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<void> processQueue() async {
    return;
  }
}
