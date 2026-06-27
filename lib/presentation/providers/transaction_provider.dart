import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

final partnerLedgerProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, partnerId) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getPartnerLedger(partnerId);
});
