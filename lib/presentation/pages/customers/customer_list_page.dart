import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capability.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
import 'create_customer_page.dart';
import 'customer_ledger_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _searchCtrl = TextEditingController();
  bool _showArchived = false;
  bool _sharedOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<AuthProvider>().businessId ?? '';
      context.read<CustomerProvider>()
        ..load(businessId)
        ..loadShared(businessId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreateCustomer() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateCustomerPage()));
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<CustomerProvider>().load(
      businessId,
      search: _searchCtrl.text.trim(),
    );
  }

  Future<void> _openEditCustomer(CustomerModel customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateCustomerPage(customer: customer)),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<CustomerProvider>().load(
      businessId,
      search: _searchCtrl.text.trim(),
    );
  }

  void _load(String businessId, String query) {
    context.read<CustomerProvider>().load(
      businessId,
      search: query.trim(),
      includeArchived: _showArchived,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId ?? '';
    final isOwner = auth.user?.role == 'owner';
    final provider = context.watch<CustomerProvider>();
    final query = _searchCtrl.text.trim().toLowerCase();

    final baseCustomers = _sharedOnly
        ? provider.customers
              .where((c) => provider.sharedCustomerIds.contains(c.id))
              .toList()
        : provider.customers;

    final visibleCustomers = query.isEmpty
        ? baseCustomers
        : baseCustomers.where((c) {
            final name = c.fullName.toLowerCase();
            final phone = (c.phone ?? '').toLowerCase();
            final shop = (c.shopName ?? '').toLowerCase();
            final city = (c.city ?? '').toLowerCase();
            return name.contains(query) ||
                phone.contains(query) ||
                shop.contains(query) ||
                city.contains(query);
          }).toList();

    Widget buildCustomerList() {
      if (provider.isLoading) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (provider.error != null) {
        return GreenCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
              const SizedBox(height: 12),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _load(businessId, _searchCtrl.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (visibleCustomers.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: EmptyState(
            icon: HeroIcons.user_group,
            title: query.isNotEmpty
                ? 'No matching customers found'
                : 'No customers in directory',
            subtitle: query.isNotEmpty
                ? 'Try modifying your search query.'
                : 'Add wholesale shopkeepers and commission customers to track ledger balances and sales.',
            actionLabel: 'Add Customer',
            onAction: _openCreateCustomer,
          ),
        );
      }
      return Column(
        children: visibleCustomers.map((customer) {
          final isShared = provider.sharedCustomerIds.contains(customer.id);
          final hasCredit = customer.outstandingBalance > 0;

          final tile = GreenCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    customer.fullName.isNotEmpty
                        ? customer.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.fullName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isShared) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.indigoSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.indigo.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'Shared',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.indigo,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [customer.shopName, customer.city, customer.phone]
                            .where((item) => item != null && item.isNotEmpty)
                            .join(' • '),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(customer.outstandingBalance),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: hasCredit ? AppColors.rose : AppColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCredit ? 'Due Credit' : 'Zero Balance',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasCredit ? AppColors.rose : AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit Customer Profile',
                  icon: const Icon(
                    HeroIcons.pencil_square,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => _openEditCustomer(customer),
                ),
              ],
            ),
          );

          if (!isOwner) {
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerLedgerPage(customer: customer),
                ),
              ),
              child: tile,
            );
          }
          return Dismissible(
            key: ValueKey('customer-${customer.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.roseSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.rose, width: 1),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(HeroIcons.archive_box, color: AppColors.rose),
            ),
            confirmDismiss: (_) async {
              final customerProv = context.read<CustomerProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final ok = await showConfirmDialog(
                context,
                title: 'Archive ${customer.fullName}?',
                message:
                    'Archived customers are hidden from the active directory and excluded from reports.',
                confirmLabel: 'Archive',
                isDestructive: true,
              );
              if (ok != true) return false;
              final archived = await customerProv.archive(customer.id);
              if (!context.mounted) return archived;
              if (archived) {
                final bId = context.read<AuthProvider>().businessId;
                if (bId != null && bId.isNotEmpty) {
                  DataRefreshNotifier.instance.refresh(bId);
                }
                messenger.showSnackBar(
                  SnackBar(content: Text('${customer.fullName} archived')),
                );
              }
              return archived;
            },
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerLedgerPage(customer: customer),
                ),
              ),
              child: tile,
            ),
          );
        }).toList(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.customersScreenTitle,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(HeroIcons.bars_3_bottom_left),
          onPressed: widget.onMenu,
        ),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(
              _showArchived ? HeroIcons.eye_slash : HeroIcons.eye,
              size: 20,
            ),
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
              final bId = context.read<AuthProvider>().businessId ?? '';
              context.read<CustomerProvider>().load(
                bId,
                search: _searchCtrl.text.trim(),
                includeArchived: _showArchived,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.indigoSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.indigo.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    HeroIcons.user_group,
                    size: 24,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer CRM & Statements',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage wholesale customer directories, credit limits, and ledger balances.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (query) => _load(businessId, query),
            decoration: InputDecoration(
              hintText: 'Search by Customer name, shop, city, or phone...',
              prefixIcon: const Icon(HeroIcons.magnifying_glass, size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(HeroIcons.x_circle, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load(businessId, '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Shared with partners'),
                avatar: const Icon(HeroIcons.share, size: 15),
                selected: _sharedOnly,
                onSelected: (val) => setState(() => _sharedOnly = val),
              ),
              if (_showArchived)
                FilterChip(
                  label: const Text('Showing archived'),
                  avatar: const Icon(HeroIcons.archive_box, size: 15),
                  selected: true,
                  onSelected: (_) {},
                ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Registered Customers (${visibleCustomers.length})',
          ),
          const SizedBox(height: 8),
          buildCustomerList(),
        ],
      ),
      floatingActionButton:
          context.watch<AuthProvider>().capabilities.can(
            Capability.createCustomer,
          )
          ? FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: _openCreateCustomer,
              icon: const Icon(HeroIcons.user_plus, size: 18),
              label: Text(
                'Add Customer',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }
}
