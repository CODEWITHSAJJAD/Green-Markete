import 'package:flutter/material.dart';
import '../../data/models/market_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CityMarketDropdown extends StatefulWidget {
  final List<MarketModel> markets;
  final String? selectedCity;
  final String? selectedMarketId;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onMarketChanged;
  final String label;

  const CityMarketDropdown({
    super.key,
    required this.markets,
    this.selectedCity,
    this.selectedMarketId,
    required this.onCityChanged,
    required this.onMarketChanged,
    this.label = 'Market',
  });

  @override
  State<CityMarketDropdown> createState() => _CityMarketDropdownState();
}

class _CityMarketDropdownState extends State<CityMarketDropdown> {
  List<String> get _cities =>
      widget.markets.map((m) => m.city).toSet().toList()..sort();

  List<MarketModel> get _filteredMarkets {
    if (widget.selectedCity == null) return [];
    return widget.markets.where((m) => m.city == widget.selectedCity).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField2<String>(
          isExpanded: true,
          valueListenable: ValueNotifier(widget.selectedCity),
          decoration: InputDecoration(labelText: '${widget.label} City'),
          items: _cities
              .map((city) => DropdownItem(value: city, child: Text(city)))
              .toList(),
          onChanged: (city) {
            widget.onCityChanged(city);
            widget.onMarketChanged(null);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField2<String>(
          isExpanded: true,
          valueListenable: ValueNotifier(widget.selectedMarketId),
          decoration: InputDecoration(labelText: widget.label),
          items: _filteredMarkets
              .map((m) => DropdownItem(value: m.id, child: Text(m.name)))
              .toList(),
          onChanged: widget.onMarketChanged,
        ),
      ],
    );
  }
}
