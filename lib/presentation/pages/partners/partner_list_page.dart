import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import 'create_partner_page.dart';
import 'partner_profile_page.dart';

class PartnerListPage extends StatefulWidget {
  const PartnerListPage({super.key});

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) context.read<PartnerProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePartnerPage()),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<PartnerProvider>().load(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final search = _searchCtrl.text.trim();
    final partnerProvider = context.watch<PartnerProvider>();
    final partners = search.isEmpty ? partnerProvider.partners : partnerProvider.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.10),
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
                Text('Business partners & access', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Manage purchasers, sellers, accountants, and invitations from one directory.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (query) {
                    context.read<PartnerProvider>().search(query, businessId);
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (partnerProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (partnerProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(partnerProvider.error.toString()),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<PartnerProvider>().load(businessId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (partners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 52, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No partners found', style: theme.textTheme.titleLarge),
                ],
              ),
            )
          else
            Column(
              children: partners
                    .map(
                      (partner) => InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PartnerProfilePage(partnerId: partner.id, initialPartner: partner),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                child: Text(
                                  partner.fullName.substring(0, 1).toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(partner.fullName, style: theme.textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      [partner.role, partner.city, partner.phone]
                                          .where((item) => item != null && item.isNotEmpty)
                                          .join('  •  '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: partner.isClaimed
                                      ? theme.colorScheme.primary.withValues(alpha: 0.10)
                                      : theme.colorScheme.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  partner.isClaimed ? 'Claimed' : 'Pending',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: partner.isClaimed ? theme.colorScheme.primary : theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('New Partner'),
      ),
    );
  }
}
