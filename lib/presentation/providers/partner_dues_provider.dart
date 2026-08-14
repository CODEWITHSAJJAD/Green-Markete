import 'package:flutter/foundation.dart';

import '../../data/models/batch_model.dart';
import '../../data/models/partner_due_model.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/batch_repository.dart';
import '../../data/repositories/transaction_repository.dart';

/// Aggregates the dues owed to seller partners for purchases: for each batch
/// with a seller partner the bill is the purchaser-side total (purchase cost +
/// purchaser expenses + purchaser daily charges + packing cost + purchaser-paid
/// transport), and settled amounts come from partner transactions matched to
/// the batch via its code in the notes/reference.
class PartnerDuesProvider extends ChangeNotifier {
  PartnerDuesProvider(this._batchRepo, this._txRepo);

  final BatchRepository _batchRepo;
  final TransactionRepository _txRepo;

  List<PartnerDueModel> _dues = const [];
  List<PartnerDueModel> get dues => _dues;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  double get totalBill =>
      _dues.fold<double>(0, (sum, d) => sum + d.totalBill);
  double get totalPaid =>
      _dues.fold<double>(0, (sum, d) => sum + d.totalPaid);
  double get totalOutstanding =>
      _dues.fold<double>(0, (sum, d) => sum + d.totalRemaining);

  Future<void> load(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      final batches = await _batchRepo.list(businessId: businessId);
      final partnerRows = await _batchRepo.listBusinessPartners(businessId);
      final transactions = await _txRepo.listByBusiness(businessId);

      final sellersByBatch = <String, List<String>>{};
      for (final row in partnerRows) {
        final role = row['role'] as String? ?? '';
        if (role != 'seller' && role != 'both') continue;
        final batchId = row['batch_id'] as String? ?? '';
        final partnerId = row['partner_id'] as String? ?? '';
        if (batchId.isEmpty || partnerId.isEmpty) continue;
        sellersByBatch.putIfAbsent(batchId, () => []).add(partnerId);
      }

      final candidates = batches
          .where((b) => sellersByBatch.containsKey(b.id))
          .toList();
      final summaries = await Future.wait(candidates.map((b) async {
        try {
          return await _batchRepo.getSummary(b.id);
        } catch (_) {
          return null;
        }
      }));

      final batchDues = <BatchDueModel>[];
      for (var i = 0; i < candidates.length; i++) {
        final batch = candidates[i];
        final pl = summaries[i];
        final bill = _billFor(batch, pl);
        final sellerIds = sellersByBatch[batch.id] ?? const <String>[];
        for (final sellerId in sellerIds) {
          final paid = transactions
              .where(
                (t) =>
                    t.toPartnerId == sellerId &&
                    ((t.notes?.contains(batch.batchCode) ?? false) ||
                        (t.reference?.contains(batch.batchCode) ?? false)),
              )
              .fold<double>(0, (sum, t) => sum + t.amount);
          batchDues.add(
            BatchDueModel(
              partnerId: sellerId,
              batchId: batch.id,
              batchCode: batch.batchCode,
              productName: batch.productName,
              bill: bill,
              paid: paid,
              remaining: (bill - paid).clamp(0, double.infinity).toDouble(),
            ),
          );
        }
      }

      final byPartner = <String, List<BatchDueModel>>{};
      for (final due in batchDues) {
        byPartner.putIfAbsent(due.partnerId, () => []).add(due);
      }
      final list =
          byPartner.entries
              .map(
                (e) => PartnerDueModel(partnerId: e.key, batches: e.value),
              )
              .toList()
            ..sort((a, b) {
              final byRemaining = b.totalRemaining.compareTo(a.totalRemaining);
              if (byRemaining != 0) return byRemaining;
              return a.partnerId.compareTo(b.partnerId);
            });
      _dues = list;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _billFor(BatchModel batch, BatchPLDetailModel? pl) {
    if (pl == null) return 0;
    final cb = pl.costBreakdown;
    return cb.purchaseCost +
        cb.purchaserDailyCharges +
        cb.purchaserExpenses +
        cb.packingCost +
        (batch.transportPaidBy == 'purchaser' ? cb.transportCost : 0);
  }
}
