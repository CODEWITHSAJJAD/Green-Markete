import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/empty_state.dart';

class SalesListPage extends ConsumerWidget {
  const SalesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/sales/new'),
        child: const Icon(Icons.add),
      ),
      body: const EmptyState(
        icon: Icons.point_of_sale_outlined,
        title: 'No sales yet',
        subtitle: 'Record your first sale',
        actionLabel: 'New Sale',
      ),
    );
  }
}
