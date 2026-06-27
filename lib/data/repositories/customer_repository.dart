import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/customer_remote_ds.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(customerRemoteDsProvider));
});

class CustomerRepository {
  final CustomerRemoteDs _remoteDs;
  CustomerRepository(this._remoteDs);

  Future<List<CustomerModel>> list(String businessId, {String? search}) {
    return _remoteDs.list(businessId, search: search);
  }

  Future<CustomerModel> create(Map<String, dynamic> data) {
    return _remoteDs.create(data);
  }

  Future<List<CustomerLedgerEntry>> getLedger(String customerId) {
    return _remoteDs.getLedger(customerId);
  }

  Future<PaymentModel> recordPayment(String customerId, PaymentCreateRequest payment) {
    return _remoteDs.recordPayment(customerId, payment);
  }
}
