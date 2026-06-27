import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/batch_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/empty_state.dart';

class BatchListPage extends ConsumerWidget {
  const BatchListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';
    final batchesAsync = ref.watch(batchListProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/batches/new'),
        child: const Icon(Icons.add),
      ),
      body: batchesAsync.when(
        data: (batches) {
          if (batches.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No batches yet',
              subtitle: 'Create your first batch to get started',
              actionLabel: 'Create Batch',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(batch.batchCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Qty: ${batch.totalQuantity} ${batch.quantityUnit}'),
                  trailing: StatusPill(status: batch.status),
                  onTap: () => context.go('/batches/${batch.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
