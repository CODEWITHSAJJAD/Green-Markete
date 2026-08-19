import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';
import '../../widgets/app_dropdown.dart';

class EditSalePage extends StatefulWidget {
  final SaleModel sale;
  final String? businessId;
  final String? batchId;

  const EditSalePage({
    super.key,
    required this.sale,
    this.businessId,
    this.batchId,
  });

  @override
  State<EditSalePage> createState() => _EditSalePageState();
}

class _EditSalePageState extends State<EditSalePage> {
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _cashCtrl;
  late final TextEditingController _bankRefCtrl;
  late final TextEditingController _notesCtrl;
  late String _paymentMode;
  String? _selectedCustomerId;
  bool _saving = false;

  SaleModel get sale => widget.sale;

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(
      text: sale.quantitySold.toStringAsFixed(
        sale.quantitySold.truncateToDouble() == sale.quantitySold ? 0 : 2,
      ),
    );
    _priceCtrl = TextEditingController(text: sale.pricePerUnit.toStringAsFixed(2));
    _cashCtrl = TextEditingController(
      text: sale.cashReceived > 0 ? sale.cashReceived.toStringAsFixed(2) : '',
    );
    _bankRefCtrl = TextEditingController(text: sale.bankReference ?? '');
    _notesCtrl = TextEditingController(text: sale.notes ?? '');
    _paymentMode = sale.paymentMode;
    _selectedCustomerId = sale.customerId;
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

  double get _qty => double.tryParse(_quantityCtrl.text.trim()) ?? 0;
  double get _price => double.tryParse(_priceCtrl.text.trim()) ?? 0;
  double get _total => _qty * _price;
  double get _cash => double.tryParse(_cashCtrl.text.trim()) ?? 0;
  double get _credit => _paymentMode == 'credit'
      ? _total
      : _paymentMode == 'partial'
          ? (_total - _cash).clamp(0.0, double.infinity)
          : 0.0;

  Future<void> _submit() async {
    if (_qty <= 0 || _price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity and price must be greater than 0')),
      );
      return;
    }
    final activeBizId = widget.businessId ?? context.read<AuthProvider>().businessId ?? '';
    final actualCash = _paymentMode == 'cash' || _paymentMode == 'bank_transfer'
        ? _total
        : _paymentMode == 'credit'
            ? 0.0
            : _cash;
    final actualCredit = (_total - actualCash).clamp(0.0, double.infinity);

    setState(() => _saving = true);
    final provider = context.read<SaleProvider>();
    final ok = await provider.update(
      sale.id,
      SaleUpdateRequest(
        quantitySold: _qty,
        pricePerUnit: _price,
        totalAmount: _total,
        paymentMode: _paymentMode,
        cashReceived: actualCash,
        creditAmount: actualCredit,
        customerId: _selectedCustomerId,
        bankReference: _bankRefCtrl.text.trim().isEmpty ? null : _bankRefCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
      businessId: activeBizId,
      batchId: widget.batchId ?? sale.batchId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      if (activeBizId.isNotEmpty) {
        DataRefreshNotifier.instance.refresh(activeBizId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale updated successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${provider.error ?? 'Unknown error'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customers = context.watch<CustomerProvider>().customers;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Sale')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customers.isNotEmpty) ...[
              AppDropdown<String?>(
                value: _selectedCustomerId,
                labelText: 'Customer (optional for walk-in)',
                items: [
                  const DropdownItem(value: null, child: Text('Direct / Walk-in Customer')),
                  for (final c in customers)
                    DropdownItem(value: c.id, child: Text(c.fullName, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _selectedCustomerId = v),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity Sold'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price per Unit (Rs)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(CurrencyFormatter.format(_total), style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              value: _paymentMode,
              labelText: 'Payment Mode',
              items: const [
                DropdownItem(value: 'cash', child: Text('Full Cash')),
                DropdownItem(value: 'credit', child: Text('Full Credit')),
                DropdownItem(value: 'partial', child: Text('Partial Payment')),
                DropdownItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (v) => setState(() {
                _paymentMode = v ?? 'cash';
                if (_paymentMode == 'cash' || _paymentMode == 'bank_transfer') {
                  _cashCtrl.text = _total > 0 ? _total.toStringAsFixed(2) : '';
                } else if (_paymentMode == 'credit') {
                  _cashCtrl.text = '0';
                }
              }),
            ),
            if (_paymentMode == 'partial') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _cashCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cash Received (Rs)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 6),
              Text(
                'Credit remaining: ${CurrencyFormatter.format(_credit)}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.rose, fontWeight: FontWeight.w600),
              ),
            ],
            if (_paymentMode == 'bank_transfer') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _bankRefCtrl,
                decoration: const InputDecoration(labelText: 'Bank Reference (optional)'),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
