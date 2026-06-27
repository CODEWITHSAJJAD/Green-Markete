import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class ExpenseEntryTile extends StatelessWidget {
  final String type;
  final double amount;
  final String? description;
  final String? partnerName;
  final String? date;
  final String? paymentMode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseEntryTile({
    super.key,
    required this.type,
    required this.amount,
    this.description,
    this.partnerName,
    this.date,
    this.paymentMode,
    this.onEdit,
    this.onDelete,
  });

  IconData get _typeIcon {
    switch (type.toLowerCase()) {
      case 'labor':
        return Icons.engineering;
      case 'daily_charge':
        return Icons.person;
      case 'stall_fee':
        return Icons.store;
      case 'transport':
      case 'local_transport':
        return Icons.local_shipping;
      case 'packing':
        return Icons.inventory;
      case 'accountant':
        return Icons.account_balance;
      default:
        return Icons.receipt;
    }
  }

  String get _typeLabel {
    switch (type.toLowerCase()) {
      case 'daily_charge':
        return 'Daily Charge';
      case 'stall_fee':
        return 'Stall Fee';
      case 'local_transport':
        return 'Local Transport';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade50,
        child: Icon(_typeIcon, color: Colors.green.shade700, size: 20),
      ),
      title: Text(_typeLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null && description!.isNotEmpty)
            Text(description!, style: const TextStyle(fontSize: 12)),
          if (partnerName != null || date != null)
            Text(
              [partnerName, date != null ? DateFormatter.toDisplay(DateTime.parse(date!)) : null]
                  .whereType<String>()
                  .join(' · '),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (paymentMode != null)
            Icon(
              paymentMode == 'bank_transfer' ? Icons.account_balance : Icons.money,
              size: 16,
              color: Colors.grey,
            ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(
              fontFamily: 'Roboto Mono',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}
