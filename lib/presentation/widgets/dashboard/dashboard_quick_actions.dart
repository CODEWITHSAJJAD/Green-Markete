import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../pages/batches/create_batch_wizard.dart';
import '../../pages/customers/record_payment_page.dart';
import '../../pages/reports/reports_page.dart';
import '../../pages/sales/quick_sale_page.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

    Widget tile(IconData icon, String label, VoidCallback onTap, Color color) {
      return GreenCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            if (canCreate)
              Expanded(
                child: tile(
                  MingCuteIcons.mgc_add_line,
                  'New Batch',
                  () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateBatchWizard(),
                    ),
                  ),
                  theme.colorScheme.primary,
                ),
              ),
            if (canSell) ...[
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  MingCuteIcons.mgc_bill_line,
                  'New Sale',
                  () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const QuickSalePage(),
                    ),
                  ),
                  theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  MingCuteIcons.mgc_wallet_3_line,
                  'Record Payment',
                  () => _recordPayment(context),
                  Colors.deepPurple,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: tile(
                MingCuteIcons.mgc_chart_bar_line,
                'Reports',
                () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                ),
                const Color(0xFF0EA5E9),
              ),
            ),
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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Customer for Payment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search customer by name, phone or city...',
                  prefixIcon: const Icon(MingCuteIcons.mgc_search_line, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          customers.isEmpty
                              ? 'No customers found.'
                              : 'No customers match your search.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          final hasDebt = customer.outstandingBalance > 0;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: hasDebt
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              child: Icon(
                                MingCuteIcons.mgc_user_3_line,
                                color: hasDebt ? Colors.red : Colors.green,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              customer.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              [
                                if (customer.city != null && customer.city!.isNotEmpty)
                                  customer.city,
                                if (customer.phone != null && customer.phone!.isNotEmpty)
                                  customer.phone,
                              ].join(' • '),
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                    customer.outstandingBalance,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: hasDebt ? Colors.red : Colors.green,
                                  ),
                                ),
                                Text(
                                  hasDebt ? 'Due balance' : 'Cleared',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasDebt
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => widget.onCustomerSelected(customer),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
