import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/batch_model.dart';
import '../../../widgets/status_pill.dart';
import '../../../widgets/amount_text.dart';

class ActiveBatchesCard extends StatelessWidget {
  final List<BatchModel> batches;

  const ActiveBatchesCard({super.key, required this.batches});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Batches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (batches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No active batches', style: TextStyle(color: Colors.grey)),
              )
            else
              ...batches.take(5).map((batch) => ListTile(
                dense: true,
                title: Text(batch.batchCode, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Qty: ${batch.totalQuantity} ${batch.quantityUnit}'),
                trailing: StatusPill(status: batch.status),
                onTap: () => context.go('/batches/${batch.id}'),
              )),
          ],
        ),
      ),
    );
  }
}
