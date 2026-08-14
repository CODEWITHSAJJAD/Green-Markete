import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/export/bill_export.dart';
import '../../../core/export/bill_model.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
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
  RealtimeChannel? _paymentsChannel;

  String get _customerId => widget.customer.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CustomerProvider>();
      provider.loadLedger(_customerId);
      _subscribeRealtime(provider);
    });
  }

  void _subscribeRealtime(CustomerProvider provider) {
    final client = SupabaseService.instance.client;
    _paymentsChannel = client
        .channel('customer_payments_$_customerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'customer_payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: _customerId,
          ),
          callback: (_) => provider.loadLedger(_customerId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'customer_payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: _customerId,
          ),
          callback: (_) => provider.loadLedger(_customerId),
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_paymentsChannel != null) {
      SupabaseService.instance.client.removeChannel(_paymentsChannel!);
    }
    super.dispose();
  }

  Future<void> _openRecordPayment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecordPaymentPage(customer: widget.customer)),
    );
    if (!mounted) return;
    context.read<CustomerProvider>().loadLedger(widget.customer.id);
  }

  Future<void> _shareStatement() async {
    final provider = context.read<CustomerProvider>();
    if (provider.ledger.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to share yet')),
      );
      return;
    }
    final businessName = context.read<BusinessProvider>().business?.name;
    final customer = widget.customer;
    final bill = BillModel(
      documentTitle: 'Credit / Clearance Statement',
      businessName: businessName,
      header: [
        BillHeaderLine('Customer', customer.fullName),
        if (customer.shopName != null && customer.shopName!.isNotEmpty) BillHeaderLine('Shop', customer.shopName!),
        if (customer.city != null && customer.city!.isNotEmpty) BillHeaderLine('City', customer.city!),
        if (customer.phone != null && customer.phone!.isNotEmpty) BillHeaderLine('Phone', customer.phone!),
      ],
      sections: [
        BillSection('Statement of account', [
          for (final e in provider.ledger)
            BillLine(
              '${e.date}  ${e.description}',
              e.type == 'payment'
                  ? '- ${CurrencyFormatter.format(e.amount)}'
                  : '+ ${CurrencyFormatter.format(e.amount)}',
            ),
        ]),
        BillSection('Summary', [
          BillLine('Total Purchased (Credit)', CurrencyFormatter.format(customer.totalPurchased)),
          BillLine('Total Cleared (Paid)', CurrencyFormatter.format(customer.totalPaid)),
        ]),
      ],
      total: BillLine('Outstanding Balance', CurrencyFormatter.format(customer.outstandingBalance), emphasize: true),
      footer: 'Please settle the outstanding balance at your earliest convenience. '
          'Generated on ${DateFormatter.toDDMMYYYY(DateTime.now())}. Amounts in ${CurrencyFormatter.currentCode}.',
    );
    await shareBill(
      context,
      bill: bill,
      fileName: 'statement_${customer.fullName.replaceAll(' ', '_')}',
      subject: 'Green Market — Credit Statement',
    );
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
                        entry.type == 'payment' ? MingCuteIcons.mgc_arrow_down_line : MingCuteIcons.mgc_arrow_up_line,
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
            tooltip: 'Share statement',
            onPressed: _shareStatement,
            icon: const Icon(MingCuteIcons.mgc_share_2_line),
          ),
          if (context.watch<AuthProvider>().canEditSellerSide)
            IconButton(
              onPressed: _openRecordPayment,
              icon: const Icon(MingCuteIcons.mgc_wallet_3_line),
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
      floatingActionButton: context.watch<AuthProvider>().canEditSellerSide
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _openRecordPayment,
              icon: const Icon(MingCuteIcons.mgc_add_line),
              label: const Text('Record Payment'),
            )
          : null,
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
