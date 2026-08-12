import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// Searchable + creatable supplier dropdown. Shows previously-used supplier
/// names from `batch_purchases` (across all batches for the business) and
/// lets the user pick one or add a new name inline.
class SupplierDropdownField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> suppliers;
  final String labelText;
  final bool required;

  const SupplierDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.suppliers,
    this.labelText = 'Supplier / shop name *',
    this.required = true,
  });

  @override
  State<SupplierDropdownField> createState() => _SupplierDropdownFieldState();
}

class _SupplierDropdownFieldState extends State<SupplierDropdownField> {
  late final TextEditingController _ctrl;
  bool _showCreateOption = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SupplierDropdownField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _query => _ctrl.text.trim();

  bool get _hasExactMatch {
    final q = _query.toLowerCase();
    if (q.isEmpty) return false;
    return widget.suppliers.any((s) => s.toLowerCase() == q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.toLowerCase();
    final matches = q.isEmpty
        ? widget.suppliers
        : widget.suppliers.where((s) => s.toLowerCase().contains(q)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: const Icon(MingCuteIcons.mgc_store_line, size: 18),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Clear',
                    onPressed: () {
                      _ctrl.clear();
                      setState(() {});
                      widget.onChanged('');
                    },
                  )
                : const Icon(Icons.arrow_drop_down, size: 18),
            hintText: widget.suppliers.isEmpty
                ? 'Type the supplier name'
                : 'Pick or type a new supplier',
          ),
          onChanged: (v) {
            setState(() {
              _showCreateOption = v.trim().isNotEmpty && !_hasExactMatch;
            });
            widget.onChanged(v);
          },
        ),
        if (matches.isNotEmpty || _showCreateOption) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in matches)
                    InkWell(
                      onTap: () {
                        _ctrl.text = s;
                        setState(() => _showCreateOption = false);
                        widget.onChanged(s);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(MingCuteIcons.mgc_store_line, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s,
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (s == widget.value)
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_showCreateOption)
                    InkWell(
                      onTap: () {
                        final name = _ctrl.text.trim();
                        if (name.isEmpty) return;
                        setState(() => _showCreateOption = false);
                        widget.onChanged(name);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Add "${_ctrl.text.trim()}" as new supplier',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
