import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// Searchable + creatable supplier dropdown. Shows previously-used supplier
/// names (from `batch_purchases` plus the historical
/// `product_batches.supplier_name` fallback) in a dropdown panel below the
/// field, and lets the user pick one or add a new name inline.
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
  final FocusNode _focus = FocusNode();
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _showCreateOption = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant SupplierDropdownField old) {
    super.didUpdateWidget(old);
    // Never clobber text while the user is typing; only sync external
    // changes (e.g. a freshly loaded supplier list) when unfocused.
    if (!_focus.hasFocus && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
    if (_focus.hasFocus) _updateOverlay();
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      _updateOverlay();
    } else if (_overlay.isShowing) {
      _overlay.hide();
    }
  }

  String get _query => _ctrl.text.trim();

  bool get _hasExactMatch {
    final q = _query.toLowerCase();
    if (q.isEmpty) return false;
    return widget.suppliers.any((s) => s.toLowerCase() == q);
  }

  List<String> get _matches {
    final q = _query.toLowerCase();
    return q.isEmpty
        ? widget.suppliers
        : widget.suppliers.where((s) => s.toLowerCase().contains(q)).toList();
  }

  void _updateOverlay() {
    if (_matches.isNotEmpty || _showCreateOption) {
      if (!_overlay.isShowing) _overlay.show();
    } else if (_overlay.isShowing) {
      _overlay.hide();
    }
  }

  void _pick(String name) {
    _ctrl.text = name;
    setState(() => _showCreateOption = false);
    if (_overlay.isShowing) _overlay.hide();
    widget.onChanged(name);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (_) => _DropdownPanel(
        link: _link,
        width: MediaQuery.sizeOf(context).width * 0.94,
        matches: _matches,
        value: widget.value,
        showCreate: _showCreateOption,
        query: _query,
        onPick: _pick,
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
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
                      setState(() => _showCreateOption = false);
                      if (_overlay.isShowing) _overlay.hide();
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
            _updateOverlay();
          },
          onTap: _updateOverlay,
        ),
      ),
    );
  }
}

class _DropdownPanel extends StatelessWidget {
  final LayerLink link;
  final double width;
  final List<String> matches;
  final String value;
  final bool showCreate;
  final String query;
  final ValueChanged<String> onPick;

  const _DropdownPanel({
    required this.link,
    required this.width,
    required this.matches,
    required this.value,
    required this.showCreate,
    required this.query,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompositedTransformFollower(
      link: link,
      targetAnchor: Alignment.topLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: 220),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in matches)
                  InkWell(
                    onTap: () => onPick(s),
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
                          if (s == value)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ),
                  ),
                if (showCreate)
                  InkWell(
                    onTap: () => onPick(query),
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
                              'Add "$query" as new supplier',
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
      ),
    );
  }
}
