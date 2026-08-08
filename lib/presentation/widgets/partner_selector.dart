import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/partner_model.dart';
import '../providers/partner_provider.dart';

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
    _partners.addAll(widget.selectedPartners.map((p) => {
          'partner_id': p.id,
          'name': p.fullName,
          'role': p.role,
          'daily_charge_rate': 0.0,
          'days_involved': 1,
        }));
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
        : (widget.selectedPartners.isNotEmpty ? widget.selectedPartners.first.businessId : '') ??
            '';
    if (businessId.isNotEmpty && provider.partners.isEmpty) {
      await provider.load(businessId);
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<PartnerModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx, setSt) {
            final partnerProvider = ctx.watch<PartnerProvider>();
            final searching = partnerProvider.isLoading;
            final searchingQuery = query.text.trim().length >= 3;
            final results = searchingQuery
                ? partnerProvider.searchResults
                : partnerProvider.partners;
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search Partner', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: query,
                    decoration: const InputDecoration(
                      hintText: 'Type 3+ characters',
                      prefixIcon: Icon(Icons.search),
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
                                    const Icon(Icons.person_search_outlined, size: 48),
                                    const SizedBox(height: 8),
                                    Text(searchingQuery
                                        ? 'No partners found'
                                        : 'No partners yet'),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: results.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final p = results[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                        child: Text(p.fullName.isEmpty ? '?' : p.fullName.substring(0, 1).toUpperCase())),
                                    title: Text(p.fullName),
                                    subtitle: Text(
                                        [p.role, p.phone].where((e) => e != null && e.toString().isNotEmpty).join(' • ')),
                                    onTap: () => Navigator.pop(ctx, p),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          }),
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
      children: [
        for (var i = 0; i < _partners.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_outline, size: 18),
                        label: Text(_partners[i]['name']?.toString() ?? 'Select Partner'),
                        onPressed: () => _pickPartner(i),
                      ),
                    ),
                    if (_partners.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => _partners.removeAt(i));
                          _emit();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _partners[i]['role'] as String,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'purchaser', child: Text('Purchaser', overflow: TextOverflow.ellipsis, maxLines: 1)),
                          DropdownMenuItem(value: 'seller', child: Text('Seller', overflow: TextOverflow.ellipsis, maxLines: 1)),
                          DropdownMenuItem(value: 'both', child: Text('Both', overflow: TextOverflow.ellipsis, maxLines: 1)),
                        ],
                        onChanged: (v) {
                          setState(() => _partners[i]['role'] = v ?? 'purchaser');
                          _emit();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _partners[i]['daily_charge_rate'].toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Daily Rate'),
                        onChanged: (v) {
                          _partners[i]['daily_charge_rate'] = double.tryParse(v) ?? 0.0;
                          _emit();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        initialValue: _partners[i]['days_involved'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Days'),
                        onChanged: (v) {
                          _partners[i]['days_involved'] = int.tryParse(v) ?? 1;
                          _emit();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _partners.add(_empty()));
              _emit();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add another partner'),
          ),
        ),
      ],
    );
  }
}
