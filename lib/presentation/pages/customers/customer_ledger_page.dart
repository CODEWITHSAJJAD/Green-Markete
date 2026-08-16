import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../widgets/empty_state.dart';
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
      MaterialPageRoute(
        builder: (_) => RecordPaymentPage(customer: widget.customer),
      ),
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
        if (customer.shopName != null && customer.shopName!.isNotEmpty)
          BillHeaderLine('Shop', customer.shopName!),
        if (customer.city != null && customer.city!.isNotEmpty)
          BillHeaderLine('City', customer.city!),
        if (customer.phone != null && customer.phone!.isNotEmpty)
          BillHeaderLine('Phone', customer.phone!),
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
          BillLine(
            'Total Purchased (Credit)',
            CurrencyFormatter.format(customer.totalPurchased),
          ),
          BillLine(
            'Total Cleared (Paid)',
            CurrencyFormatter.format(customer.totalPaid),
          ),
        ]),
      ],
      total: BillLine(
        'Outstanding Balance',
        CurrencyFormatter.format(customer.outstandingBalance),
        emphasize: true,
      ),
      footer:
          'Please settle the outstanding balance at your earliest convenience. '
          'Generated on ${DateFormatter.toDDMMYYYY(DateTime.now())}. Amounts in ${CurrencyFormatter.currentCode}.',
    );
    await shareBill(
      context,
      bill: bill,
      fileName: 'statement_${customer.fullName.replaceAll(' ', '_')}',
      subject: 'MandiRoznamcha — Credit Statement',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    Widget ledgerSection;
    if (provider.isLoading) {
      ledgerSection = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (provider.error != null) {
      ledgerSection = Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          provider.error!.toString(),
          style: GoogleFonts.inter(color: AppColors.rose),
        ),
      );
    } else if (provider.ledger.isEmpty) {
      ledgerSection = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: EmptyState(
          icon: HeroIcons.receipt_percent,
          title: 'No transaction activity',
          subtitle:
              'Sales invoices and payments recorded for this Customer will appear in this ledger.',
        ),
      );
    } else {
      ledgerSection = Column(
        children: provider.ledger
            .map(
              (entry) => GreenCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (entry.type == 'payment'
                            ? AppColors.emeraldSurface
                            : AppColors.roseSurface),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        entry.type == 'payment'
                            ? HeroIcons.arrow_down_left
                            : HeroIcons.arrow_up_right,
                        color: entry.type == 'payment'
                            ? AppColors.emeraldDark
                            : AppColors.rose,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.date,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.type == 'payment' ? '-' : '+'} ${CurrencyFormatter.format(entry.amount)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: entry.type == 'payment'
                                ? AppColors.emeraldDark
                                : AppColors.rose,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bal: ${CurrencyFormatter.format(entry.runningBalance)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Customer Ledger',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share statement',
            onPressed: _shareStatement,
            icon: const Icon(HeroIcons.share, size: 20),
          ),
          if (context.watch<AuthProvider>().canEditSellerSide)
            IconButton(
              tooltip: 'Record Payment',
              onPressed: _openRecordPayment,
              icon: const Icon(HeroIcons.banknotes, size: 20),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          GreenCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                        widget.customer.shopName,
                        widget.customer.city,
                        widget.customer.phone,
                      ]
                      .where((item) => item != null && item.isNotEmpty)
                      .join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        'Total Credit',
                        CurrencyFormatter.format(
                          widget.customer.totalPurchased,
                        ),
                        AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        'Total Cleared',
                        CurrencyFormatter.format(widget.customer.totalPaid),
                        AppColors.emeraldDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        'Outstanding Due',
                        CurrencyFormatter.format(
                          widget.customer.outstandingBalance,
                        ),
                        widget.customer.outstandingBalance > 0
                            ? AppColors.rose
                            : AppColors.emeraldDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CreditIndicator(
                  totalPurchased: widget.customer.totalPurchased,
                  totalPaid: widget.customer.totalPaid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Transaction & Payment Timeline'),
          const SizedBox(height: 10),
          ledgerSection,
        ],
      ),
      floatingActionButton: context.watch<AuthProvider>().canEditSellerSide
          ? FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
              onPressed: _openRecordPayment,
              icon: const Icon(HeroIcons.banknotes, size: 20),
              label: Text(
                'Record Payment',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }

  Widget _metricTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
