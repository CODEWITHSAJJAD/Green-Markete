import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/credit_indicator.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
import 'record_payment_page.dart';

class CustomerLedgerPage extends StatefulWidget {
  final CustomerModel customer;

  const CustomerLedgerPage({super.key, required this.customer});

  @override
  State<CustomerLedgerPage> createState() => _CustomerLedgerPageState();
}

class _CustomerLedgerPageState extends State<CustomerLedgerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadLedger(widget.customer.id);
    });
  }

  Future<void> _openRecordPayment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecordPaymentPage(customer: widget.customer)),
    );
    if (!mounted) return;
    context.read<CustomerProvider>().loadLedger(widget.customer.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final theme = Theme.of(context);

    Widget ledgerSection;
    if (provider.isLoading) {
      ledgerSection = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (provider.error != null) {
      ledgerSection = Text(provider.error!.toString());
    } else if (provider.ledger.isEmpty) {
      ledgerSection = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No credit or payment activity yet.'),
      );
    } else {
      ledgerSection = Column(
        children: provider.ledger
            .map(
              (entry) => GreenCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: entry.type == 'payment'
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.secondary.withValues(alpha: 0.12),
                      child: Icon(
                        entry.type == 'payment' ? MingCute.arrow_down_line : MingCute.arrow_up_line,
                        color: entry.type == 'payment' ? theme.colorScheme.primary : theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.description, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(entry.date, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(CurrencyFormatter.format(entry.amount), style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Bal: ${CurrencyFormatter.format(entry.runningBalance)}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger'),
        actions: [
          IconButton(
            onPressed: _openRecordPayment,
            icon: const Icon(MingCute.wallet_3_line),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.customer.fullName, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  [widget.customer.shopName, widget.customer.city, widget.customer.phone]
                      .where((item) => item != null && item.isNotEmpty)
                      .join('  •  '),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metric(theme, 'Purchased', CurrencyFormatter.format(widget.customer.totalPurchased)),
                    _metric(theme, 'Paid', CurrencyFormatter.format(widget.customer.totalPaid)),
                    _metric(theme, 'Outstanding', CurrencyFormatter.format(widget.customer.outstandingBalance)),
                  ],
                ),
                const SizedBox(height: 20),
                CreditIndicator(
                  totalPurchased: widget.customer.totalPurchased,
                  totalPaid: widget.customer.totalPaid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Transaction history'),
          const SizedBox(height: 12),
          ledgerSection,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordPayment,
        icon: const Icon(MingCute.add_line),
        label: const Text('Record Payment'),
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
