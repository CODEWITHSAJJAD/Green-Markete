import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_model.dart';
import '../providers/partner_provider.dart';
import 'app_dropdown.dart';

class PartnerSelector extends StatefulWidget {
  final List<PartnerModel> selectedPartners;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final String businessId;

  const PartnerSelector({
    super.key,
    required this.selectedPartners,
    required this.onChanged,
    this.businessId = '',
  });

  @override
  State<PartnerSelector> createState() => _PartnerSelectorState();
}

class _PartnerSelectorState extends State<PartnerSelector> {
  final List<Map<String, dynamic>> _partners = [];

  @override
  void initState() {
    super.initState();
    _partners.addAll(
      widget.selectedPartners.map(
        (p) => {
          'partner_id': p.id,
          'name': p.fullName,
          'role': p.role,
          'daily_charge_rate': 0.0,
          'days_involved': 1,
        },
      ),
    );
    if (_partners.isEmpty) _partners.add(_empty());
  }

  Map<String, dynamic> _empty() => {
    'partner_id': null,
    'name': null,
    'role': 'purchaser',
    'daily_charge_rate': 0.0,
    'days_involved': 1,
  };

  void _emit() => widget.onChanged(List<Map<String, dynamic>>.from(_partners));

  Future<void> _pickPartner(int index) async {
    final provider = context.read<PartnerProvider>();
    final query = TextEditingController();
    final businessId = widget.businessId.isNotEmpty
        ? widget.businessId
        : (widget.selectedPartners.isNotEmpty
                  ? widget.selectedPartners.first.businessId
                  : '') ??
              '';
    if (businessId.isNotEmpty && provider.partners.isEmpty) {
      await provider.load(businessId);
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<PartnerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              final partnerProvider = ctx.watch<PartnerProvider>();
              final searching = partnerProvider.isLoading;
              final searchingQuery = query.text.trim().length >= 3;
              final results = searchingQuery
                  ? partnerProvider.searchResults
                  : partnerProvider.partners;
              return Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Partner',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: query,
                      decoration: const InputDecoration(
                        hintText: 'Search by partner name or phone...',
                        prefixIcon: Icon(MingCuteIcons.mgc_search_line, size: 18),
                      ),
                      onChanged: (value) {
                        setSt(() {});
                        provider.search(value, businessId);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: searching
                          ? const Center(child: CircularProgressIndicator())
                          : results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    MingCuteIcons.mgc_user_3_line,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    searchingQuery
                                        ? 'No matching partners found'
                                        : 'No partners available',
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final p = results[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      p.fullName.isEmpty
                                          ? '?'
                                          : p.fullName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    p.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [p.role.toUpperCase(), p.phone]
                                        .where(
                                          (e) =>
                                              e != null &&
                                              e.toString().isNotEmpty,
                                        )
                                        .join(' • '),
                                  ),
                                  onTap: () => Navigator.pop(ctx, p),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _partners[index] = {
          'partner_id': result.id,
          'name': result.fullName,
          'role': _partners[index]['role'] ?? result.role,
          'daily_charge_rate': _partners[index]['daily_charge_rate'] ?? 0.0,
          'days_involved': _partners[index]['days_involved'] ?? 1,
        };
      });
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _partners.length; i++)
          Builder(
            builder: (context) {
              final p = _partners[i];
              final rate = (p['daily_charge_rate'] as num?)?.toDouble() ?? 0.0;
              final days = (p['days_involved'] as num?)?.toInt() ?? 1;
              final totalPartnerCharge = rate * days;
              final partnerName = p['name']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Partner ${i + 1}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_partners.length > 1)
                          IconButton(
                            icon: const Icon(
                              MingCuteIcons.mgc_delete_3_line,
                              size: 20,
                              color: Colors.red,
                            ),
                            tooltip: 'Remove partner',
                            onPressed: () {
                              setState(() => _partners.removeAt(i));
                              _emit();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _pickPartner(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: partnerName != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: partnerName != null
                              ? theme.colorScheme.primary.withValues(alpha: 0.04)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MingCuteIcons.mgc_user_3_line,
                              size: 20,
                              color: partnerName != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                partnerName ?? 'Tap to select partner *',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: partnerName != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: partnerName != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Icon(
                              MingCuteIcons.mgc_arrow_right_line,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      value: p['role'] as String,
                      labelText: 'Partner Role',
                      prefixIcon: const Icon(
                        MingCuteIcons.mgc_user_4_line,
                        size: 18,
                      ),
                      items: const [
                        DropdownItem(
                          value: 'purchaser',
                          child: Text('Purchaser'),
                        ),
                        DropdownItem(
                          value: 'seller',
                          child: Text('Seller'),
                        ),
                        DropdownItem(
                          value: 'both',
                          child: Text('Both (Purchaser & Seller)'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => p['role'] = v ?? 'purchaser');
                        _emit();
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: p['daily_charge_rate'].toString(),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Daily Rate (Rs)',
                              prefixIcon: Icon(
                                MingCuteIcons.mgc_wallet_3_line,
                                size: 18,
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                p['daily_charge_rate'] =
                                    double.tryParse(v) ?? 0.0;
                              });
                              _emit();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: p['days_involved'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Days',
                              prefixIcon: Icon(
                                MingCuteIcons.mgc_calendar_line,
                                size: 18,
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                p['days_involved'] = int.tryParse(v) ?? 1;
                              });
                              _emit();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (totalPartnerCharge > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MingCuteIcons.mgc_wallet_3_line,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Auto charge: ${CurrencyFormatter.format(totalPartnerCharge)} ($days days × ${CurrencyFormatter.format(rate)})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _partners.add(_empty()));
              _emit();
            },
            icon: const Icon(MingCuteIcons.mgc_add_line),
            label: const Text('Add another partner'),
          ),
        ),
      ],
    );
  }
}
