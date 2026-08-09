import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class QuickSalePage extends StatefulWidget {
  const QuickSalePage({super.key});

  @override
  State<QuickSalePage> createState() => _QuickSalePageState();
}

class _QuickSalePageState extends State<QuickSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _bankRefCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  BatchModel? _selectedBatch;
  CustomerModel? _selectedCustomer;
  String _paymentMode = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context.read<BatchListProvider>().load(businessId, status: 'selling');
      context.read<CustomerProvider>().load(businessId);
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _cashCtrl.dispose();
    _bankRefCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBatch == null) return;
    final auth = context.read<AuthProvider>();
    final quantity = double.parse(_quantityCtrl.text.trim());
    final price = double.parse(_priceCtrl.text.trim());
    final cashReceived = _cashCtrl.text.trim().isEmpty
        ? 0.0
        : double.parse(_cashCtrl.text.trim());
    final totalAmount = quantity * price;
    final creditAmount = _paymentMode == 'partial_credit'
        ? (totalAmount - cashReceived)
        : _paymentMode == 'credit'
        ? totalAmount
        : 0.0;

    setState(() => _saving = true);
    final ok = await context.read<SaleProvider>().add(
      SaleCreateRequest(
        batchId: _selectedBatch!.id,
        sellerId: auth.userId,
        customerId: _selectedCustomer?.id,
        saleDate: DateTime.now().toIso8601String().split('T').first,
        quantitySold: quantity,
        pricePerUnit: price,
        paymentMode: _paymentMode,
        cashReceived: cashReceived,
        creditAmount: creditAmount,
        bankReference: _bankRefCtrl.text.trim().isEmpty
            ? null
            : _bankRefCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _load();
      final businessId = auth.businessId;
      if (businessId != null && businessId.isNotEmpty) {
        DataRefreshNotifier.instance.refresh(businessId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<SaleProvider>().error ?? 'Failed to record sale',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesProvider = context.watch<BatchListProvider>();
    final customersProvider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Sale')),
      body: _buildBody(context, batchesProvider, customersProvider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BatchListProvider batchesProvider,
    CustomerProvider customersProvider,
  ) {
    if (batchesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (batchesProvider.error != null) {
      return Center(child: Text(batchesProvider.error!));
    }
    if (customersProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (customersProvider.error != null) {
      return Center(child: Text(customersProvider.error!));
    }

    final batchList = batchesProvider.batches;
    final customerList = customersProvider.customers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField2<BatchModel>(
              isExpanded: true,
              valueListenable: ValueNotifier(_selectedBatch),
              decoration: const InputDecoration(labelText: 'Batch'),
              items: batchList
                  .map(
                    (batch) => DropdownItem(
                      value: batch,
                      child: Text(
                        '${batch.batchCode} â€¢ ${batch.productName ?? 'Batch'}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedBatch = value),
              validator: (value) => value == null ? 'Select a batch' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField2<CustomerModel?>(
              isExpanded: true,
              valueListenable: ValueNotifier(_selectedCustomer),
              decoration: const InputDecoration(labelText: 'Customer'),
              items: [
                const DropdownItem<CustomerModel?>(
                  value: null,
                  child: Text('Walk-in customer'),
                ),
                ...customerList.map(
                  (customer) => DropdownItem<CustomerModel?>(
                    value: customer,
                    child: Text(customer.fullName),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedCustomer = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Quantity sold'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price per unit'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField2<String>(
              isExpanded: true,
              valueListenable: ValueNotifier(_paymentMode),
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: const [
                DropdownItem(value: 'cash', child: Text('Cash')),
                DropdownItem(value: 'credit', child: Text('Credit')),
                DropdownItem(
                  value: 'partial_credit',
                  child: Text('Partial credit'),
                ),
                DropdownItem(
                  value: 'bank_transfer',
                  child: Text('Bank transfer'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _paymentMode = value ?? 'cash'),
            ),
            if (_paymentMode == 'partial_credit' ||
                _paymentMode == 'bank_transfer') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _cashCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _paymentMode == 'partial_credit'
                      ? 'Cash received'
                      : 'Cash received (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankRefCtrl,
                decoration: const InputDecoration(labelText: 'Bank reference'),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Sale'),
            ),
          ],
        ),
      ),
    );
  }
}
