import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  static const _tables = [
    'product_batches',
    'sales',
    'expenses',
    'packing_records',
    'customer_payments',
    'customers',
  ];

  final _repo = AuditRepository();
  String? _tableFilter;
  DateTimeRange? _range;
  List<AuditLogModel>? _entries;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.list(
        performedBy: userId,
        tableName: _tableFilter,
        from: _range?.start,
        to: _range?.end != null
            ? DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59)
            : null,
      );
      if (!mounted) return;
      setState(() {
        _entries = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            tooltip: 'Date range',
            icon: const Icon(MingCuteIcons.mgc_calendar_3_line),
            onPressed: _pickRange,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Filter by table'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _tableFilter == null,
                onSelected: (_) {
                  setState(() => _tableFilter = null);
                  _load();
                },
              ),
              for (final t in _tables)
                ChoiceChip(
                  label: Text(t.replaceAll('_', ' ')),
                  selected: _tableFilter == t,
                  onSelected: (_) {
                    setState(() => _tableFilter = t);
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('${_range!.start.toString().split(' ').first} → ${_range!.end.toString().split(' ').first}'),
                    onDeleted: () {
                      setState(() => _range = null);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            )
          else if (_entries == null || _entries!.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: MingCuteIcons.mgc_shield_line,
                title: 'No audit entries',
                subtitle: 'Your activity will appear here as you make changes.',
              ),
            )
          else
            ..._entries!.map(_tile),
        ],
      ),
    );
  }

  Widget _tile(AuditLogModel entry) {
    final theme = Theme.of(context);
    final color = switch (entry.action) {
      'INSERT' => AppColors.success,
      'UPDATE' => theme.colorScheme.primary,
      'DELETE' => theme.colorScheme.error,
      'VOID' => theme.colorScheme.error,
      _ => theme.colorScheme.outline,
    };
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            switch (entry.action) {
              'INSERT' => MingCuteIcons.mgc_add_line,
              'UPDATE' => MingCuteIcons.mgc_edit_2_line,
              'DELETE' => MingCuteIcons.mgc_delete_3_line,
              'VOID' => MingCuteIcons.mgc_forbid_circle_line,
              _ => MingCuteIcons.mgc_information_line,
            },
            size: 20,
            color: color,
          ),
        ),
        title: Text(
          '${entry.action}  •  ${entry.tableName.replaceAll('_', ' ')}',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          entry.createdAt ?? '-',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(MingCuteIcons.mgc_arrow_right_line, size: 16, color: AppColors.textTertiary),
      ),
    );
  }
}