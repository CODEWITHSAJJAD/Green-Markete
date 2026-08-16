import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../pages/batches/create_batch_wizard.dart';
import '../../pages/customers/record_payment_page.dart';
import '../../pages/reports/reports_page.dart';
import '../../pages/sales/quick_sale_page.dart';
import '../../pages/suppliers/supplier_settlement_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capability.dart';
import '../../providers/customer_provider.dart';
import '../green_card.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  void _recordPayment(BuildContext context) {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    final customerProv = context.read<CustomerProvider>();
    if (customerProv.customers.isEmpty) {
      customerProv.load(businessId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CustomerPaymentPicker(
        onCustomerSelected: (customer) {
          Navigator.of(ctx).pop();
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => RecordPaymentPage(customer: customer),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.capabilities.can(Capability.createBatch);
    final canSell = auth.canEditSellerSide;
    final canRecordPayment = auth.capabilities.can(Capability.recordPayment);

    Widget actionCard(IconData icon, String title, String subtitle, VoidCallback onTap, Color color) {
      return GreenCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final card1 = canCreate
        ? actionCard(
            HeroIcons.plus,
            'New Batch',
            'Log arrival',
            () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const CreateBatchWizard()),
            ),
            AppColors.primary,
          )
        : actionCard(
            HeroIcons.building_storefront,
            'Suppliers',
            'Settlements',
            () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const SupplierSettlementPage()),
            ),
            AppColors.amber,
          );

    final card2 = canSell
        ? actionCard(
            HeroIcons.shopping_cart,
            'Quick Sale',
            'Sell produce',
            () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const QuickSalePage()),
            ),
            AppColors.secondary,
          )
        : actionCard(
            HeroIcons.chart_bar,
            'Analytics',
            'View metrics',
            () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const ReportsPage()),
            ),
            AppColors.indigo,
          );

    final card3 = canRecordPayment
        ? actionCard(
            HeroIcons.banknotes,
            'Collect Cash',
            'Receive dues',
            () => _recordPayment(context),
            AppColors.emerald,
          )
        : actionCard(
            HeroIcons.chart_bar,
            'Statements',
            'Accounts',
            () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const ReportsPage()),
            ),
            AppColors.emerald,
          );

    final card4 = actionCard(
      HeroIcons.chart_bar,
      'P&L Reports',
      'Statements',
      () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const ReportsPage()),
      ),
      AppColors.indigo,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Operations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 10),
            Expanded(child: card2),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: card3),
            const SizedBox(width: 10),
            Expanded(child: card4),
          ],
        ),
      ],
    );
  }
}

class _CustomerPaymentPicker extends StatefulWidget {
  final ValueChanged<CustomerModel> onCustomerSelected;

  const _CustomerPaymentPicker({required this.onCustomerSelected});

  @override
  State<_CustomerPaymentPicker> createState() => _CustomerPaymentPickerState();
}

class _CustomerPaymentPickerState extends State<_CustomerPaymentPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customers = context.watch<CustomerProvider>().customers;
    final filtered = _query.isEmpty
        ? customers
        : customers
            .where(
              (c) =>
                  c.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                  (c.phone != null && c.phone!.contains(_query)) ||
                  (c.city != null &&
                      c.city!.toLowerCase().contains(_query.toLowerCase())),
            )
            .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Customer for Payment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(HeroIcons.x_mark, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search buyer by name, phone or city...',
                prefixIcon: const Icon(HeroIcons.magnifying_glass, size: 18),
                fillColor: AppColors.surfaceAlt,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(HeroIcons.x_circle, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            HeroIcons.user_minus,
                            size: 40,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No customers found',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final hasCredit = c.outstandingBalance > 0;
                        return InkWell(
                          onTap: () => widget.onCustomerSelected(c),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider, width: 1),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primarySurface,
                                  child: Text(
                                    c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.fullName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [c.phone, c.city].where((e) => e != null && e.isNotEmpty).join(' • '),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
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
                                      CurrencyFormatter.format(c.outstandingBalance),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: hasCredit ? AppColors.rose : AppColors.emerald,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasCredit ? 'Outstanding Due' : 'Zero Balance',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: hasCredit ? AppColors.rose : AppColors.emerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
