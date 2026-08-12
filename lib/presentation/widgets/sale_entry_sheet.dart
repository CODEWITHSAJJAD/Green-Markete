import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/batch_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/sale_model.dart';
import '../providers/auth_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/customer_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// Returns `true` when a sale was actually saved, `null`/`false` otherwise.
Future<bool?> showSaleEntrySheet(
  BuildContext context, {
  required BatchModel batch,
  double? suggestedPrice,
  double soldQuantity = 0,
}) {
  return showModalBottomSheet(
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
  final _formKey = GlobalKey<FormState>();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final remaining = widget.batch.totalQuantity - widget.soldQuantity;
    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter quantity and price')));
      return;
    }
    if (qty > remaining + 0.0001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${remaining.toStringAsFixed(0)} ${widget.batch.unit} remaining for this batch',
          ),
        ),
      );
      return;
    }
    final cash = _cashCtrl.text.trim().isEmpty
        ? 0.0
        : double.tryParse(_cashCtrl.text.trim()) ?? 0;
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
        bankReference: _bankRefCtrl.text.trim().isEmpty
            ? null
            : _bankRefCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sale recorded')));
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Record Sale', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${widget.batch.batchCode} • ${widget.batch.productName ?? ''}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showModalBottomSheet<CustomerModel?>(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => _CustomerPicker(
                      customers: customers,
                      initial: _customer,
                    ),
                  );
                  if (!mounted) return;
                  setState(() => _customer = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Customer'),
                  child: Text(
                    _customer?.fullName ?? 'Walk-in customer',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _customer == null
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity (${widget.batch.unit})',
                  helperText:
                      'Only ${remaining.toStringAsFixed(0)} ${widget.batch.unit} remaining (of ${widget.batch.totalQuantity.toStringAsFixed(0)})',
                  errorText: overLimit ? 'Exceeds remaining quantity' : null,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                  if (n > remaining + 0.0001)
                    return 'Exceeds remaining quantity';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price per unit'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField2<String>(
                isExpanded: true,
                valueListenable: ValueNotifier(_paymentMode),
                decoration: const InputDecoration(labelText: 'Payment mode'),
                items: const [
                  DropdownItem(value: 'cash', child: Text('Cash')),
                  DropdownItem(value: 'credit', child: Text('Credit')),
                  DropdownItem(
                    value: 'partial_credit',
                    child: Text('Partial Credit'),
                  ),
                  DropdownItem(
                    value: 'bank_transfer',
                    child: Text('Bank Transfer'),
                  ),
                ],
                onChanged: (v) => setState(() => _paymentMode = v ?? 'cash'),
              ),
              if (_paymentMode == 'partial_credit' ||
                  _paymentMode == 'bank_transfer') ...[
                const SizedBox(height: 12),
                TextField(
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
                const SizedBox(height: 12),
                TextField(
                  controller: _bankRefCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bank reference',
                  ),
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
      ),
    );
  }
}

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker({required this.customers, this.initial});

  final List<CustomerModel> customers;
  final CustomerModel? initial;

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.customers.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.fullName.toLowerCase().contains(q) ||
          (c.phone?.toLowerCase().contains(q) ?? false) ||
          (c.city?.toLowerCase().contains(q) ?? false) ||
          (c.shopName?.toLowerCase().contains(q) ?? false);
    }).toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search customer',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Walk-in customer'),
              subtitle: const Text('No customer on this sale'),
              selected: widget.initial == null,
              onTap: () => Navigator.pop(context, null),
            ),
            const Divider(height: 1),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          _query.isEmpty ? 'No customers yet' : 'No matches',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          title: Text(c.fullName),
                          subtitle: Text(
                            [
                                  if (c.phone != null && c.phone!.isNotEmpty)
                                    c.phone,
                                  if (c.city != null && c.city!.isNotEmpty)
                                    c.city,
                                  if (c.shopName != null &&
                                      c.shopName!.isNotEmpty)
                                    c.shopName,
                                ]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(' • '),
                          ),
                          selected: widget.initial?.id == c.id,
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
