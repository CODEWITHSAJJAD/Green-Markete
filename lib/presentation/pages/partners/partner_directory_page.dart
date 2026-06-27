import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/partner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/partner_model.dart';
import '../../widgets/empty_state.dart';

class PartnerDirectoryPage extends ConsumerStatefulWidget {
  const PartnerDirectoryPage({super.key});

  @override
  ConsumerState<PartnerDirectoryPage> createState() => _PartnerDirectoryPageState();
}

class _PartnerDirectoryPageState extends ConsumerState<PartnerDirectoryPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';
    final partnersAsync = ref.watch(partnerListProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Directory')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/partners/new'),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search partners...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) {
                if (q.length >= 3) {
                  ref.read(partnerSearchNotifierProvider.notifier).search(q, businessId);
                }
              },
            ),
          ),
          Expanded(
            child: partnersAsync.when(
              data: (partners) {
                if (partners.isEmpty) {
                  return const EmptyState(
                    icon: Icons.group_outlined,
                    title: 'No partners found',
                    actionLabel: 'Add Partner',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final partner = partners[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            partner.fullName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(partner.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${partner.city ?? ''} · ${partner.role}'),
                        trailing: Chip(
                          label: Text(
                            partner.accessLevel ?? 'viewer',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: partner.accessLevel == 'editor'
                              ? Colors.green.shade100
                              : Colors.grey.shade100,
                          padding: EdgeInsets.zero,
                        ),
                        onTap: () => context.go('/partners/${partner.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}
