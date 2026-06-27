import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/market_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/market_model.dart';
import '../../../data/repositories/market_repository.dart';

class MarketManagementPage extends ConsumerStatefulWidget {
  const MarketManagementPage({super.key});

  @override
  ConsumerState<MarketManagementPage> createState() => _MarketManagementPageState();
}

class _MarketManagementPageState extends ConsumerState<MarketManagementPage> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _stallController = TextEditingController();
  String _marketType = 'wholesale';
  bool _showAddForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _stallController.dispose();
    super.dispose();
  }

  Future<void> _addMarket() async {
    final authState = ref.read(authProvider);
    final businessId = authState.user?.id ?? '';
    final repo = ref.read(marketRepositoryProvider);
    await repo.create({
      'business_id': businessId,
      'name': _nameController.text.trim(),
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      'stall_number': _stallController.text.trim(),
      'market_type': _marketType,
    });
    ref.invalidate(marketListProvider(businessId));
    _nameController.clear();
    _cityController.clear();
    _addressController.clear();
    _stallController.clear();
    setState(() => _showAddForm = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';
    final marketsAsync = ref.watch(marketListProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Markets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showAddForm = !_showAddForm),
        child: Icon(_showAddForm ? Icons.close : Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_showAddForm)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Market Name *')),
                    const SizedBox(height: 12),
                    TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City *')),
                    const SizedBox(height: 12),
                    TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 12),
                    TextField(controller: _stallController, decoration: const InputDecoration(labelText: 'Stall Number')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _marketType,
                      decoration: const InputDecoration(labelText: 'Market Type'),
                      items: const [
                        DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                        DropdownMenuItem(value: 'retail', child: Text('Retail')),
                        DropdownMenuItem(value: 'both', child: Text('Both')),
                      ],
                      onChanged: (v) => setState(() => _marketType = v!),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addMarket,
                        child: const Text('Add Market'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Markets', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          marketsAsync.when(
            data: (markets) {
              if (markets.isEmpty) return const Text('No markets added yet', style: TextStyle(color: Colors.grey));
              final grouped = <String, List<MarketModel>>{};
              for (final m in markets) {
                grouped.putIfAbsent(m.city, () => []).add(m);
              }
              return Column(
                children: grouped.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${entry.value.length} markets'),
                      children: entry.value.map((m) => ListTile(
                        title: Text(m.name),
                        subtitle: Text('${m.address ?? ''} · ${m.stallNumber ?? ''}'),
                      )).toList(),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }
}
