import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final String? hintText;
  final String? createNewLabel;
  final VoidCallback? onCreateNew;
  final ValueChanged<T?> onChanged;
  final String Function(T)? filterText;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.itemLabel,
    this.hintText,
    this.createNewLabel,
    this.onCreateNew,
    required this.onChanged,
    this.filterText,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isOpen = false;

  List<T> get _filteredItems {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items.where((item) {
      final label = widget.filterText?.call(item) ?? widget.itemLabel(item);
      return label.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Search...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.selectedItem != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.onChanged(null);
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
          onTap: () {
            setState(() => _isOpen = true);
          },
        ),
        if (_isOpen && _searchController.text.isNotEmpty || _isOpen && widget.items.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                ..._filteredItems.map((item) => ListTile(
                  dense: true,
                  title: Text(widget.itemLabel(item)),
                  selected: item == widget.selectedItem,
                  onTap: () {
                    widget.onChanged(item);
                    _searchController.text = widget.itemLabel(item);
                    setState(() => _isOpen = false);
                  },
                )),
                if (widget.createNewLabel != null && _searchController.text.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                    title: Text(widget.createNewLabel!, style: const TextStyle(color: Colors.green)),
                    onTap: () {
                      widget.onCreateNew?.call();
                      setState(() => _isOpen = false);
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
