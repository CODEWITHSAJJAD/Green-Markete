import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/batch_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/sale_model.dart';
import '../providers/auth_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/customer_provider.dart';

Future<void> showSaleEntrySheet(
  BuildContext context, {
  required BatchModel batch,
  double? suggestedPrice,
  double soldQuantity = 0,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _SaleEntrySheet(
        batch: batch,
        suggestedPrice: suggestedPrice,
        soldQuantity: soldQuantity,
      ),
    ),
  );
}

class _SaleEntrySheet extends StatefulWidget {
  final BatchModel batch;
  final double? suggestedPrice;
  final double soldQuantity;

  const _SaleEntrySheet({
    required this.batch,
    this.suggestedPrice,
    this.soldQuantity = 0,
  });

  @override
  State<_SaleEntrySheet> createState() => _SaleEntrySheetState();
}

class _SaleEntrySheetState extends State<_SaleEntrySheet> {
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _bankRefCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  CustomerModel? _customer;
  String _paymentMode = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedPrice != null) {
      _priceCtrl.text = widget.suggestedPrice.toString();
    }
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
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

  Future<void> _save() async {
    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final remaining = widget.batch.totalQuantity - widget.soldQuantity;
    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter quantity and price')));
      return;
    }
    if (qty > remaining + 0.0001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${remaining.toStringAsFixed(0)} ${widget.batch.unit} remaining for this batch')),
      );
      return;
    }
    final cash = _cashCtrl.text.trim().isEmpty ? 0.0 : double.tryParse(_cashCtrl.text.trim()) ?? 0;
    final total = qty * price;
    final credit = _paymentMode == 'partial_credit'
        ? (total - cash).clamp(0, total).toDouble()
        : _paymentMode == 'credit'
            ? total
            : 0.0;

    setState(() => _saving = true);
    final ok = await context.read<SaleProvider>().add(
          SaleCreateRequest(
            batchId: widget.batch.id,
            sellerId: context.read<AuthProvider>().userId,
            customerId: _customer?.id,
            saleDate: DateTime.now().toIso8601String().split('T').first,
            quantitySold: qty,
            pricePerUnit: price,
            paymentMode: _paymentMode,
            cashReceived: cash,
            creditAmount: credit,
            bankReference: _bankRefCtrl.text.trim().isEmpty ? null : _bankRefCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customers = context.watch<CustomerProvider>().customers;
    final remaining = widget.batch.totalQuantity - widget.soldQuantity;
    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final overLimit = qty > remaining + 0.0001;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Record Sale', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${widget.batch.batchCode} • ${widget.batch.productName ?? ''}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomerModel?>(
              initialValue: _customer,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: [
                const DropdownMenuItem<CustomerModel?>(value: null, child: Text('Walk-in customer')),
                ...customers.map((c) => DropdownMenuItem<CustomerModel?>(
                      value: c,
                      child: Text(c.fullName),
                    )),
              ],
              onChanged: (v) => setState(() => _customer = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (${widget.batch.unit})',
                helperText: 'Only ${remaining.toStringAsFixed(0)} ${widget.batch.unit} remaining (of ${widget.batch.totalQuantity.toStringAsFixed(0)})',
                errorText: overLimit ? 'Exceeds remaining quantity' : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price per unit'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'credit', child: Text('Credit')),
                DropdownMenuItem(value: 'partial_credit', child: Text('Partial Credit')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (v) => setState(() => _paymentMode = v ?? 'cash'),
            ),
            if (_paymentMode == 'partial_credit' || _paymentMode == 'bank_transfer') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cashCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _paymentMode == 'partial_credit' ? 'Cash received' : 'Cash received (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bankRefCtrl,
                decoration: const InputDecoration(labelText: 'Bank reference'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_saving || overLimit) ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Sale'),
            ),
          ],
        ),
      ),
    );
  }
}
