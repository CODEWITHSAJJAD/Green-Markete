import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../widgets/amount_text.dart';

class QuickSalePage extends ConsumerStatefulWidget {
  const QuickSalePage({super.key});

  @override
  ConsumerState<QuickSalePage> createState() => _QuickSalePageState();
}

class _QuickSalePageState extends ConsumerState<QuickSalePage> {
  int _step = 0;
  dynamic _selectedBatch;
  dynamic _selectedCustomer;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _cashReceivedController = TextEditingController();
  final _bankRefController = TextEditingController();
  String _paymentMode = 'cash';

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _cashReceivedController.dispose();
    _bankRefController.dispose();
    super.dispose();
  }

  Future<void> _confirmSale() async {
    final authState = ref.read(authProvider);
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final cash = double.tryParse(_cashReceivedController.text) ?? 0;
    final total = qty * price;
    final credit = _paymentMode == 'credit'
        ? total
        : _paymentMode == 'partial_credit'
            ? total - cash
            : 0.0;

    final request = SaleCreateRequest(
      batchId: _selectedBatch.id,
      sellerId: authState.user?.id,
      customerId: _selectedCustomer?.id,
      saleDate: DateFormatter.toISO(DateTime.now()),
      quantitySold: qty,
      pricePerUnit: price,
      paymentMode: _paymentMode,
      cashReceived: cash,
      creditAmount: credit,
      bankReference: _bankRefController.text.isNotEmpty ? _bankRefController.text : null,
    );

    final repo = ref.read(saleRepositoryProvider);
    await repo.create(request);
    ref.invalidate(batchDetailProvider(_selectedBatch.id));
    ref.invalidate(batchPLProvider(_selectedBatch.id));
    if (mounted) context.go('/batches/${_selectedBatch.id}');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';
    final batchesAsync = ref.watch(batchListProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_step + 1) / 5),
            const SizedBox(height: 24),
            if (_step == 0) ...[
              const Text('Select Batch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              batchesAsync.when(
                data: (batches) => SearchableDropdown(
                  items: batches.where((b) => b.status == 'selling').toList(),
                  itemLabel: (b) => '${b.batchCode}',
                  hintText: 'Search selling batches...',
                  onChanged: (batch) {
                    setState(() { _selectedBatch = batch; _step = 1; });
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
            ],
            if (_step == 1) ...[
              const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Customer Name'),
                onSubmitted: (_) => setState(() => _step = 2),
              ),
              TextButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('Skip - Walk-in Customer'),
              ),
            ],
            if (_step == 2) ...[
              const Text('Quantity & Price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price Per Unit'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _step = 3),
                child: const Text('Next'),
              ),
            ],
            if (_step == 3) ...[
              const Text('Payment Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('Cash'), selected: _paymentMode == 'cash', onSelected: (_) => setState(() => _paymentMode = 'cash')),
                  ChoiceChip(label: const Text('Credit'), selected: _paymentMode == 'credit', onSelected: (_) => setState(() => _paymentMode = 'credit')),
                  ChoiceChip(label: const Text('Part Credit'), selected: _paymentMode == 'partial_credit', onSelected: (_) => setState(() => _paymentMode = 'partial_credit')),
                ],
              ),
              if (_paymentMode == 'partial_credit') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _cashReceivedController,
                  decoration: const InputDecoration(labelText: 'Cash Received'),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_paymentMode == 'bank_transfer') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _bankRefController,
                  decoration: const InputDecoration(labelText: 'Bank Reference'),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _step = 4),
                child: const Text('Review'),
              ),
            ],
            if (_step == 4) ...[
              const Text('Confirm Sale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Batch: ${_selectedBatch?.batchCode ?? ''}'),
                      Text('Qty: ${_quantityController.text} × PKR ${_priceController.text}'),
                      AmountText(amount: (double.tryParse(_quantityController.text) ?? 0) * (double.tryParse(_priceController.text) ?? 0)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmSale,
                  child: const Text('Confirm Sale'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
