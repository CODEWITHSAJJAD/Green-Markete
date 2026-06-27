import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';

Future<Map<String, dynamic>?> showSaleEntrySheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _SaleEntrySheet(),
  );
}

class _SaleEntrySheet extends StatefulWidget {
  const _SaleEntrySheet();

  @override
  State<_SaleEntrySheet> createState() => _SaleEntrySheetState();
}

class _SaleEntrySheetState extends State<_SaleEntrySheet> {
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _cashReceivedController = TextEditingController();
  final _bankRefController = TextEditingController();
  String _paymentMode = 'cash';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _cashReceivedController.dispose();
    _bankRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Sale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
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
            const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                _PaymentChip('Cash', 'cash'),
                const SizedBox(width: 8),
                _PaymentChip('Credit', 'credit'),
                const SizedBox(width: 8),
                _PaymentChip('Part Credit', 'partial_credit'),
                if (_paymentMode != 'cash' && _paymentMode != 'credit')
                  const SizedBox(width: 8),
                if (_paymentMode != 'cash' && _paymentMode != 'credit')
                  _PaymentChip('Bank', 'bank_transfer'),
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
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormatter.toDDMMYYYY(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(_quantityController.text) ?? 0;
                  final price = double.tryParse(_priceController.text) ?? 0;
                  final cash = double.tryParse(_cashReceivedController.text) ?? 0;
                  final total = qty * price;
                  final credit = _paymentMode == 'credit'
                      ? total
                      : _paymentMode == 'partial_credit'
                          ? total - cash
                          : 0.0;
                  Navigator.pop(context, {
                    'quantity_sold': qty,
                    'price_per_unit': price,
                    'total_amount': total,
                    'payment_mode': _paymentMode,
                    'cash_received': cash,
                    'credit_amount': credit,
                    'bank_reference': _bankRefController.text,
                    'sale_date': DateFormatter.toISO(_date),
                  });
                },
                child: const Text('Confirm Sale'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _PaymentChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _paymentMode == value,
      onSelected: (v) => setState(() => _paymentMode = value),
    );
  }
}
