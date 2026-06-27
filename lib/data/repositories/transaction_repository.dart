import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/transaction_remote_ds.dart';
import '../models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(transactionRemoteDsProvider));
});

class TransactionRepository {
  final TransactionRemoteDs _remoteDs;
  TransactionRepository(this._remoteDs);

  Future<TransactionModel> create(TransactionCreateRequest request) {
    return _remoteDs.create(request);
  }

  Future<Map<String, dynamic>> getPartnerLedger(String partnerId) {
    return _remoteDs.getPartnerLedger(partnerId);
  }
}
