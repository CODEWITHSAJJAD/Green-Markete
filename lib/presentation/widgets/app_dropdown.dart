import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// Standard item definition for [AppDropdown].
class AppDropdownItem<T> {
  final T value;
  final String label;
  final Widget? leading;
  final Widget? child;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.leading,
    this.child,
  });
}

/// A standardized, reusable dropdown form field for the entire app.
/// Provides consistent styling, validation, icon support, and smooth overlay behavior.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(T?)? validator;
  final bool isExpanded;
  final bool enabled;
  final double menuMaxHeight;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool filled;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.isExpanded = true,
    this.enabled = true,
    this.menuMaxHeight = 250,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.fillColor,
    this.filled = true,
  });

  /// Factory constructor to easily build dropdown from a list of objects and a label function.
  factory AppDropdown.fromList({
    Key? key,
    required T? value,
    required List<T> items,
    String Function(T)? itemLabel,
    required ValueChanged<T?>? onChanged,
    Widget Function(T)? leadingBuilder,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(T?)? validator,
    bool isExpanded = true,
    bool enabled = true,
    double menuMaxHeight = 250,
    EdgeInsetsGeometry? contentPadding,
    Color? fillColor,
    bool filled = true,
  }) {
    final getLabel = itemLabel ?? (T item) => item.toString();
    return AppDropdown<T>(
      key: key,
      value: value,
      items: items.map((item) {
        return DropdownItem<T>(
          value: item,
          child: leadingBuilder != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leadingBuilder(item),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        getLabel(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  getLabel(item),
                  overflow: TextOverflow.ellipsis,
                ),
        );
      }).toList(),
      onChanged: onChanged,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      validator: validator,
      isExpanded: isExpanded,
      enabled: enabled,
      menuMaxHeight: menuMaxHeight,
      contentPadding: contentPadding,
      fillColor: fillColor,
      filled: filled,
    );
  }

  /// Factory constructor from simple key-value entries
  factory AppDropdown.fromEntries({
    Key? key,
    required T? value,
    required List<AppDropdownItem<T>> entries,
    required ValueChanged<T?>? onChanged,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(T?)? validator,
    bool isExpanded = true,
    bool enabled = true,
    double menuMaxHeight = 250,
    EdgeInsetsGeometry? contentPadding,
    Color? fillColor,
    bool filled = true,
  }) {
    return AppDropdown<T>(
      key: key,
      value: value,
      items: entries.map((entry) {
        return DropdownItem<T>(
          value: entry.value,
          child: entry.child ??
              (entry.leading != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        entry.leading!,
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            entry.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      entry.label,
                      overflow: TextOverflow.ellipsis,
                    )),
        );
      }).toList(),
      onChanged: onChanged,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      validator: validator,
      isExpanded: isExpanded,
      enabled: enabled,
      menuMaxHeight: menuMaxHeight,
      contentPadding: contentPadding,
      fillColor: fillColor,
      filled: filled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(10);

    return DropdownButtonFormField2<T>(
      valueListenable: ValueNotifier(value),
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        isDense: true,
        filled: filled,
        fillColor: fillColor ?? theme.colorScheme.surfaceContainerLowest,
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: menuMaxHeight,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      iconStyleData: IconStyleData(
        icon: Icon(
          Icons.arrow_drop_down,
          color: enabled ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
        ),
      ),
    );
  }
}
