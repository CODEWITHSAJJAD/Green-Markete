import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../core/config/theme.dart';

/// Searchable + creatable supplier dropdown matching [AppDropdown] aesthetics.
/// Shows previously-used supplier names in a dropdown panel below the field,
/// and lets the user pick one or create a new name inline.
class SupplierDropdownField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> suppliers;
  final String labelText;
  final bool required;

  /// Called when the user creates a NEW supplier name via the
  /// "Add … as new supplier" row — used to persist it into the registry.
  final ValueChanged<String>? onCreateSupplier;

  const SupplierDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.suppliers,
    this.labelText = 'Supplier / shop name *',
    this.required = true,
    this.onCreateSupplier,
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
    if (!_focus.hasFocus && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChanged() => _updateOverlay();

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
    if (!mounted) return;
    final shouldShow = _focus.hasFocus && (_matches.isNotEmpty || _showCreateOption);
    if (shouldShow == _overlay.isShowing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldShow) {
        if (!_overlay.isShowing) _overlay.show();
      } else if (_overlay.isShowing) {
        _overlay.hide();
      }
    });
  }

  void _pick(String name) {
    _ctrl.text = name;
    setState(() => _showCreateOption = false);
    if (_overlay.isShowing) _overlay.hide();
    final isNew = !widget.suppliers.any(
      (s) => s.toLowerCase() == name.toLowerCase(),
    );
    widget.onChanged(name);
    if (isNew) widget.onCreateSupplier?.call(name);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (context) {
        final renderBox = context.findRenderObject() as RenderBox?;
        final width = renderBox != null && renderBox.hasSize
            ? renderBox.size.width
            : MediaQuery.sizeOf(context).width * 0.9;
        return _DropdownPanel(
          link: _link,
          width: width,
          matches: _matches,
          value: widget.value,
          showCreate: _showCreateOption,
          query: _query,
          onPick: _pick,
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: TextFormField(
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
                : const Icon(MingCuteIcons.mgc_arrow_down_line, size: 18),
            hintText: widget.suppliers.isEmpty
                ? 'Type supplier name'
                : 'Pick or type supplier',
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
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 6),
      child: Material(
        elevation: 6,
        shadowColor: AppColors.shadow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          constraints: BoxConstraints(maxWidth: width, maxHeight: 240),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in matches)
                    InkWell(
                      onTap: () => onPick(s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MingCuteIcons.mgc_store_line,
                              size: 18,
                              color: s == value
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: s == value
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: s == value
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (s == value)
                              Icon(
                                MingCuteIcons.mgc_check_line,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (showCreate) ...[
                    if (matches.isNotEmpty)
                      const Divider(height: 1, indent: 12, endIndent: 12),
                    InkWell(
                      onTap: () => onPick(query),
                      child: Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.06),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MingCuteIcons.mgc_add_circle_line,
                              size: 18,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
