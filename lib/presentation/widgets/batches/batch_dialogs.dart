import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/packing_return_model.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../../providers/data_refresh.dart';
import '../../providers/partner_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../app_dropdown.dart';
import '../confirm_dialog.dart';

const List<String> batchStatusFlow = [
  'purchased',
  'packed',
  'in_transit',
  'delivered',
  'selling',
  'closed',
];

Future<void> showAddPackingDialog(BuildContext context, String batchId) async {
  final unitTypeCtrl = TextEditingController(text: 'bag');
  final countCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  String unitType = 'bag';

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Add Packing Record'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppDropdown<String>(
                    value: unitType,
                    labelText: 'Unit type',
                    items: const [
                      DropdownItem(value: 'bag', child: Text('Bag')),
                      DropdownItem(value: 'packet', child: Text('Packet')),
                      DropdownItem(value: 'crate', child: Text('Crate')),
                      DropdownItem(value: 'box', child: Text('Box')),
                      DropdownItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (v) => setSt(() {
                      unitType = v ?? 'bag';
                      unitTypeCtrl.text = unitType;
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unitTypeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit label (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Count'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cost per unit',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final count = int.tryParse(countCtrl.text.trim()) ?? 0;
                  final cost = double.tryParse(costCtrl.text.trim()) ?? 0;
                  if (count <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Count must be > 0')),
                    );
                    return;
                  }
                  try {
                    await context.read<BatchDetailProvider>().addPacking(
                      PackingRecordCreate(
                        unitType: unitType,
                        unitLabel: unitTypeCtrl.text.trim().isEmpty
                            ? null
                            : unitTypeCtrl.text.trim(),
                        unitCount: count,
                        costPerUnit: cost,
                      ),
                    );
                    if (!context.mounted) return;
                    context.read<BatchPLProvider>().load(batchId);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showAddReturnDialog(BuildContext context, String batchId) async {
  final detailProvider = context.read<BatchDetailProvider>();
  final packing = detailProvider.packingRecords;
  final theme = Theme.of(context);
  if (packing.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add a packing record first')),
    );
    return;
  }
  String? packingIndex;
  final quantityCtrl = TextEditingController();
  final countCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Record Return'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<String>(
                value: packingIndex,
                labelText: 'Packing record',
                items: [
                  for (var i = 0; i < packing.length; i++)
                    DropdownItem(
                      value: '$i',
                      child: Text(
                        '${i + 1}. ${packing[i].unitLabel ?? packing[i].unitType} × ${packing[i].unitCount}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => packingIndex = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantity returned',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Count (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Return value is estimated from the linked packing record’s cost per unit.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final idx = int.tryParse(packingIndex ?? '') ?? -1;
              if (idx < 0 || idx >= packing.length) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Select a packing record')),
                );
                return;
              }
              final quantity = double.tryParse(quantityCtrl.text.trim()) ?? 0;
              if (quantity <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Quantity must be > 0')),
                );
                return;
              }
              try {
                await detailProvider.addReturn(
                  PackingReturnCreate(
                    packingRecordId: packing[idx].id,
                    quantity: quantity,
                    count: int.tryParse(countCtrl.text.trim()),
                    returnDate: DateTime.now()
                        .toIso8601String()
                        .split('T')
                        .first,
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  ),
                );
                if (!ctx.mounted) return;
                context.read<BatchPLProvider>().load(batchId);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<void> showAddTransportDialog(BuildContext context, String batchId) async {
  final vehiclesProvider = context.read<VehicleProvider>();
  final businessId = context.read<AuthProvider>().businessId;
  if (businessId != null &&
      businessId.isNotEmpty &&
      vehiclesProvider.vehicles.isEmpty) {
    await vehiclesProvider.load(businessId);
  }
  if (!context.mounted) return;
  final vehicles = vehiclesProvider.vehicles;
  final packing = context.read<BatchDetailProvider>().packingRecords;
  final detailProvider = context.read<BatchDetailProvider>();
  String? vehicleId;
  int? packingIndex;
  String costType = 'per_vehicle';
  final unitCountCtrl = TextEditingController(text: '0');
  final transportCostCtrl = TextEditingController(text: '0');

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Add Vehicle Load'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppDropdown<String>(
                    value: vehicleId,
                    labelText: 'Vehicle',
                    items: [
                      for (final v in vehicles)
                        DropdownItem(
                          value: v.id,
                          child: Text(
                            v.plateNumber,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setSt(() => vehicleId = v),
                  ),
                  if (packing.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AppDropdown<int>(
                      value: packingIndex,
                      labelText: 'Packing record (optional)',
                      items: [
                        for (var i = 0; i < packing.length; i++)
                          DropdownItem(
                            value: i,
                            child: Text(
                              '${i + 1}. ${packing[i].unitLabel ?? packing[i].unitType} × ${packing[i].unitCount}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setSt(() => packingIndex = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    value: costType,
                    labelText: 'Cost type',
                    items: const [
                      DropdownItem(
                        value: 'per_vehicle',
                        child: Text('Flat per vehicle'),
                      ),
                      DropdownItem(
                        value: 'per_packing',
                        child: Text('Per unit loaded'),
                      ),
                      DropdownItem(
                        value: 'lump_sum',
                        child: Text('Lump sum'),
                      ),
                    ],
                    onChanged: (v) =>
                        setSt(() => costType = v ?? 'per_vehicle'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unitCountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Units loaded',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: transportCostCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: costType == 'per_packing'
                          ? 'Transport cost per unit'
                          : 'Transport cost',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (vehicleId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Select a vehicle')),
                    );
                    return;
                  }
                  try {
                    await detailProvider.addVehicleLoad(
                      VehicleLoadCreate(
                        vehicleId: vehicleId!,
                        packingRecordId: packingIndex != null
                            ? packing[packingIndex!].id
                            : null,
                        unitCount:
                            double.tryParse(unitCountCtrl.text.trim()) ?? 0,
                        costType: costType,
                        transportCost:
                            double.tryParse(transportCostCtrl.text.trim()) ??
                            0,
                        loadDate: DateTime.now()
                            .toIso8601String()
                            .split('T')
                            .first,
                      ),
                    );
                    if (!ctx.mounted) return;
                    context.read<BatchPLProvider>().load(batchId);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showPayTransportDialog(
  BuildContext context, {
  required BatchModel batch,
  required double totalCost,
  required String transportPartnerId,
}) async {
  final theme = Theme.of(context);
  final businessId = context.read<AuthProvider>().businessId ?? '';
  final side = batch.transportPaidBy ?? 'purchaser';
  final partners = context.read<PartnerProvider>().partners;

  String partnerName(String id) {
    return partners
            .where((p) => p.id == id)
            .map((p) => p.fullName)
            .firstOrNull ??
        id;
  }

  final amountCtrl = TextEditingController(
    text: totalCost > 0 ? totalCost.toStringAsFixed(2) : '',
  );
  final notesCtrl = TextEditingController(
    text: 'Transport payment for batch ${batch.batchCode}',
  );
  final refCtrl = TextEditingController();
  String paymentMode = 'cash';

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Pay Transport'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'The ${side == 'seller' ? 'seller' : 'purchaser'} side pays the vehicle fares directly. This is recorded as a ${side == 'seller' ? 'seller' : 'purchaser'}-side transport expense.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Paid by: ${partnerName(transportPartnerId)} (${side == 'seller' ? 'Seller' : 'Purchaser'})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total transport fare: ${CurrencyFormatter.format(totalCost)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  value: paymentMode,
                  labelText: 'Payment mode',
                  items: const [
                    DropdownItem(value: 'cash', child: Text('Cash')),
                    DropdownItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer'),
                    ),
                  ],
                  onChanged: (v) => setSt(() => paymentMode = v ?? 'cash'),
                ),
                if (paymentMode == 'bank_transfer') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank reference',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                  return;
                }
                final expenseProvider = context.read<ExpenseProvider>();
                final ok = await expenseProvider.add(
                  batch.id,
                  ExpenseCreate(
                    expenseSide: side,
                    expenseType: 'transport',
                    amount: amount,
                    description: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                    paidBy: transportPartnerId,
                    paymentMode: paymentMode,
                    paymentReference: refCtrl.text.trim().isEmpty
                        ? null
                        : refCtrl.text.trim(),
                    expenseDate: DateTime.now()
                        .toIso8601String()
                        .split('T')
                        .first,
                  ),
                );
                if (!ctx.mounted) return;
                if (ok) {
                  context.read<BatchPLProvider>().load(batch.id);
                  if (businessId.isNotEmpty) {
                    DataRefreshNotifier.instance.refresh(businessId);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transport payment recorded'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed: ${expenseProvider.error ?? 'Unknown error'}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save Payment'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> showCollectWalkInCreditDialog(
  BuildContext context,
  SaleModel sale,
) async {
  final theme = Theme.of(context);
  final businessId = context.read<AuthProvider>().businessId ?? '';
  final remaining = sale.creditAmount;
  final amountCtrl = TextEditingController(
    text: remaining > 0 ? remaining.toStringAsFixed(2) : '',
  );
  final bankRefCtrl = TextEditingController();
  String paymentMode = 'cash';

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Collect Walk-in Credit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Outstanding credit: ${CurrencyFormatter.format(remaining)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  value: paymentMode,
                  labelText: 'Payment mode',
                  items: const [
                    DropdownItem(value: 'cash', child: Text('Cash')),
                    DropdownItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer'),
                    ),
                  ],
                  onChanged: (v) => setSt(() => paymentMode = v ?? 'cash'),
                ),
                if (paymentMode == 'bank_transfer') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: bankRefCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank reference',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                  return;
                }
                if (amount > remaining + 0.01) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Amount exceeds outstanding credit'),
                    ),
                  );
                  return;
                }
                final saleProvider = context.read<SaleProvider>();
                final ok = await saleProvider.collectCredit(
                  sale.id,
                  amount: amount,
                  paymentMode: paymentMode,
                  bankReference: bankRefCtrl.text.trim().isEmpty
                      ? null
                      : bankRefCtrl.text.trim(),
                );
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.pop(ctx);
                  context.read<BatchPLProvider>().load(sale.batchId);
                  if (businessId.isNotEmpty) {
                    DataRefreshNotifier.instance.refresh(businessId);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Credit collected')),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed: ${saleProvider.error ?? 'Unknown error'}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Collect'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> showSettleSellerDialog(
  BuildContext context, {
  required BatchModel batch,
  required String sellerId,
  required String sellerName,
  required double remaining,
  required double settledForBatch,
}) async {
  final theme = Theme.of(context);
  final businessId = context.read<AuthProvider>().businessId ?? '';
  final batchPartners = context.read<BatchDetailProvider>().batchPartners;
  final partners = context.read<PartnerProvider>().partners;
  final purchasers = batchPartners
      .where((p) => p['role'] == 'purchaser' || p['role'] == 'both')
      .map((p) => p['partner_id'] as String?)
      .whereType<String>()
      .toList();
  String? fromPartnerId = purchasers.isNotEmpty ? purchasers.first : null;
  final amountCtrl = TextEditingController(
    text: remaining > 0 ? remaining.toStringAsFixed(2) : '',
  );
  final notesCtrl = TextEditingController(
    text: 'Settlement for batch ${batch.batchCode}',
  );
  String paymentMode = 'cash';

  String partnerName(String id) {
    return partners
            .where((p) => p.id == id)
            .map((p) => p.fullName)
            .firstOrNull ??
        id;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return AlertDialog(
          title: Text('Settle $sellerName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdown<String>(
                  value: fromPartnerId,
                  labelText: 'Paid by (partner)',
                  items: [
                    for (final p in purchasers)
                      DropdownItem(
                        value: p,
                        child: Text(
                          partnerName(p),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setSt(() => fromPartnerId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    helperText: 'Enter a partial amount to pay in splits',
                  ),
                ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  value: paymentMode,
                  labelText: 'Payment mode',
                  items: const [
                    DropdownItem(value: 'cash', child: Text('Cash')),
                    DropdownItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer'),
                    ),
                  ],
                  onChanged: (v) => setSt(() => paymentMode = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Owed: ${CurrencyFormatter.format(remaining)} · Settled: ${CurrencyFormatter.format(settledForBatch)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                  return;
                }
                if (fromPartnerId == null || fromPartnerId!.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Select who is paying')),
                  );
                  return;
                }
                final txProvider = context.read<TransactionProvider>();
                try {
                  final created = await txProvider.create(
                    TransactionCreateRequest(
                      businessId: businessId,
                      fromPartnerId: fromPartnerId!,
                      toPartnerId: sellerId,
                      amount: amount,
                      transactionType: 'settlement',
                      paymentMode: paymentMode,
                      transactionDate: DateTime.now()
                          .toIso8601String()
                          .split('T')
                          .first,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    ),
                  );
                  if (created != null) {
                    txProvider.loadLedger(sellerId);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed: ${txProvider.error ?? 'Unknown error'}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Settlement'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> advanceBatchStatus(
  BuildContext context,
  String batchId,
  String currentStatus,
) async {
  final index = batchStatusFlow.indexOf(currentStatus);
  if (index < 0 || index == batchStatusFlow.length - 1) return;

  final nextStatus = batchStatusFlow[index + 1];
  final auth = context.read<AuthProvider>();

  // Purchaser can advance up to 'delivered'. 'selling' and 'closed' are managed by Seller or Owner.
  if ((nextStatus == 'selling' || nextStatus == 'closed') &&
      !auth.canEditSellerSide &&
      !auth.capabilities.isOwner) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextStatus == 'selling'
              ? 'Batch is delivered. Only the seller or business owner can start selling.'
              : 'Only the seller or business owner can close a batch.',
        ),
      ),
    );
    return;
  }

  if (nextStatus == 'closed') {
    await confirmCloseBatch(context, batchId);
    return;
  }

  try {
    final success = await context.read<BatchDetailProvider>().updateStatus(nextStatus);
    if (!context.mounted) return;
    if (success) {
      context.read<BatchPLProvider>().load(batchId);
      final businessId = context.read<AuthProvider>().businessId;
      if (businessId != null && businessId.isNotEmpty) {
        DataRefreshNotifier.instance.refresh(businessId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch status updated to ${nextStatus.replaceAll('_', ' ')}'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }
}

Future<void> confirmCloseBatch(BuildContext context, String batchId) async {
  final auth = context.read<AuthProvider>();
  if (!auth.capabilities.can(Capability.closeBatch)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to close batches.'),
      ),
    );
    return;
  }

  final confirm = await showConfirmDialog(
    context,
    title: 'Mark batch as closed?',
    message:
        'Closing a batch is permanent — it locks all edits, sales, packing, and expenses for this batch. Use this when the batch is fully settled.',
    confirmLabel: 'Mark as closed',
    isDestructive: true,
  );
  if (!confirm) return;
  if (!context.mounted) return;
  final provider = context.read<BatchDetailProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final businessId = context.read<AuthProvider>().businessId;
  try {
    await provider.updateStatus('closed');
    if (businessId != null && businessId.isNotEmpty) {
      DataRefreshNotifier.instance.refresh(businessId);
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Batch marked as closed')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
    );
  }
}
