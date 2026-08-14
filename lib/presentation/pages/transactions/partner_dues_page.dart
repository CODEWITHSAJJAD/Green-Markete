import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_due_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_dues_provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../batches/batch_detail_page.dart';
import 'partner_settlement_page.dart';

class PartnerDuesPage extends StatefulWidget {
  const PartnerDuesPage({super.key});

  @override
  State<PartnerDuesPage> createState() => _PartnerDuesPageState();
}

class _PartnerDuesPageState extends State<PartnerDuesPage> {
  String get _businessId => context.read<AuthProvider>().businessId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _businessId;
      if (id.isNotEmpty) {
        context.read<PartnerProvider>().load(id);
        context.read<PartnerDuesProvider>().load(id);
      }
    });
  }

  Future<void> _reload() async {
    final id = _businessId;
    if (id.isEmpty) return;
    await context.read<PartnerDuesProvider>().load(id);
  }

  String _partnerName(String id) {
    final partners = context.read<PartnerProvider>().partners;
    return partners
            .where((p) => p.id == id)
            .map((p) => p.fullName)
            .firstOrNull ??
        id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PartnerDuesProvider>();
    context.watch<PartnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Dues')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary.withValues(alpha: 0.10),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dues to partners', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Purchaser-side bills owed to seller partners for purchases, paid fully or in splits. Open a partner to see each batch.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metric(
                        theme,
                        'Total bill',
                        CurrencyFormatter.format(provider.totalBill),
                      ),
                      _metric(
                        theme,
                        'Paid',
                        CurrencyFormatter.format(provider.totalPaid),
                      ),
                      _metric(
                        theme,
                        'Outstanding',
                        CurrencyFormatter.format(provider.totalOutstanding),
                        color: provider.totalOutstanding > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PartnerSettlementPage(),
                        ),
                      );
                      if (mounted) _reload();
                    },
                    icon: const Icon(MingCuteIcons.mgc_exchange_dollar_line),
                    label: const Text('Record Settlement'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(provider.error.toString()),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (provider.dues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: EmptyState(
                  icon: MingCuteIcons.mgc_wallet_3_line,
                  title: 'No dues to partners',
                  subtitle:
                      'Add a seller partner to a batch purchase and its purchaser-side bill will appear here.',
                ),
              )
            else
              ...provider.dues.map((d) => _dueCard(theme, d)),
          ],
        ),
      ),
    );
  }

  Widget _dueCard(ThemeData theme, PartnerDueModel due) {
    final name = _partnerName(due.partnerId);
    final remaining = due.totalRemaining;
    final settled = remaining <= 0.01;
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: settled
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
              child: Icon(
                settled
                    ? MingCuteIcons.mgc_check_circle_fill
                    : MingCuteIcons.mgc_time_line,
                color: settled ? AppColors.success : AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            'Bill ${CurrencyFormatter.format(due.totalBill)} · Paid ${CurrencyFormatter.format(due.totalPaid)}',
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(due.totalRemaining),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: settled ? AppColors.success : AppColors.error,
              ),
            ),
            Text(
              settled ? 'Settled' : 'Outstanding',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        children: [
          for (final b in due.batches) ...[
            if (b != due.batches.first) const Divider(height: 16),
            _batchDueRow(theme, b),
          ],
        ],
      ),
    );
  }

  Widget _batchDueRow(ThemeData theme, BatchDueModel due) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    due.batchCode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (due.productName != null && due.productName!.isNotEmpty)
                    Text(
                      due.productName!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BatchDetailPage(batchId: due.batchId),
                ),
              ),
              child: const Text('Open'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Bill ${CurrencyFormatter.format(due.bill)} · Paid ${CurrencyFormatter.format(due.paid)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(
              CurrencyFormatter.format(due.remaining),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: due.isFullySettled
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metric(ThemeData theme, String label, String value, {Color? color}) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
