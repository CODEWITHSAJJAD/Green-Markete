import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
class BusinessSwitcherPage extends StatefulWidget {
  const BusinessSwitcherPage({super.key});

  @override
  State<BusinessSwitcherPage> createState() => _BusinessSwitcherPageState();
}

class _BusinessSwitcherPageState extends State<BusinessSwitcherPage> {
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().loadBusinesses();
    });
  }

  Future<void> _switchTo(String businessId, String businessName) async {
    final auth = context.read<AuthProvider>();
    if (businessId == auth.businessId) return;
    setState(() => _switching = true);
    await auth.switchBusiness(businessId);
    if (!mounted) return;
    setState(() => _switching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to $businessName')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _createBusiness() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    String businessType = 'multi_partner';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('Add new business'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Business name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'single', label: Text('Single')),
                        ButtonSegment(value: 'multi_partner', label: Text('Multi Partner')),
                      ],
                      selected: {businessType},
                      onSelectionChanged: (v) => setSt(() => businessType = v.first),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );

    if (created != true || !mounted) return;

    final business = await context.read<BusinessProvider>().create(
          name: nameCtrl.text.trim(),
          city: cityCtrl.text.trim(),
          businessType: businessType,
        );
    if (!mounted) return;
    if (business == null) {
      final error = context.read<BusinessProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create business: $error')),
      );
      return;
    }
    await context.read<AuthProvider>().switchBusiness(business.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${business.name} created and set as active')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final businesses = auth.businesses;
    final activeId = auth.businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Businesses')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Your Businesses'),
          const SizedBox(height: 4),
          if (businesses.isEmpty)
            const GreenCard(
              padding: EdgeInsets.all(20),
              child: Text('No businesses found.'),
            )
          else
            for (final b in businesses)
              Builder(
                builder: (ctx) {
                  final membership = auth.memberships
                      .where((m) => m.businessId == b.id)
                      .firstOrNull;
                  final roleLabel = membership == null
                      ? (b.businessType == 'single'
                          ? 'Single owner'
                          : 'Multi partner')
                      : auth.describeMembership(membership).split(' — ').last;
                  return GreenCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: EdgeInsets.zero,
                    color: b.id == activeId ? AppColors.primary.withValues(alpha: 0.06) : null,
                    borderColor: b.id == activeId ? AppColors.primary : null,
                    onTap: _switching
                        ? null
                        : () => _switchTo(b.id, b.name),
                    child: ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(MingCuteIcons.mgc_store_2_line, size: 20, color: AppColors.primary),
                      ),
                      title: Text(b.name, style: theme.textTheme.bodyLarge),
                      subtitle: Text(roleLabel),
                      trailing: b.id == activeId
                          ? const Icon(MingCuteIcons.mgc_check_circle_fill, color: AppColors.primary, size: 22)
                          : const Icon(MingCuteIcons.mgc_arrow_right_line, color: AppColors.textTertiary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createBusiness,
            icon: const Icon(MingCuteIcons.mgc_add_line, size: 18),
            label: const Text('Add New Business'),
          ),
        ],
      ),
    );
  }
}
