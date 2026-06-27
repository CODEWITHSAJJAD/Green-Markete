import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/batch_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/market_provider.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/market_model.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/batch_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../widgets/city_market_dropdown.dart';
import 'widgets/partner_selector.dart';
import 'widgets/packing_entry_form.dart';
import 'widgets/batch_summary_card.dart';
import '../../../data/repositories/batch_repository.dart';

class CreateBatchWizard extends ConsumerStatefulWidget {
  const CreateBatchWizard({super.key});

  @override
  ConsumerState<CreateBatchWizard> createState() => _CreateBatchWizardState();
}

class _CreateBatchWizardState extends ConsumerState<CreateBatchWizard> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _createBatch() async {
    final wizardState = ref.read(batchWizardProvider);
    final authState = ref.read(authProvider);
    final businessId = authState.user?.id ?? '';

    final request = BatchCreateRequest(
      businessId: businessId,
      productId: wizardState.productId!,
      sourceMarketId: wizardState.sourceMarketId,
      destinationMarketId: wizardState.destinationMarketId,
      purchaseDate: wizardState.purchaseDate ?? DateFormatter.toISO(DateTime.now()),
      totalQuantity: wizardState.totalQuantity ?? 0,
      quantityUnit: wizardState.quantityUnit ?? 'kg',
      purchasePricePerUnit: wizardState.purchasePricePerUnit ?? 0,
      transportPaidBy: wizardState.transportPaidBy,
    );

    try {
      final repo = ref.read(batchRepositoryProvider);
      final batch = await repo.create(request);
      ref.read(batchWizardProvider.notifier).reset();
      if (mounted) context.go('/batches/${batch.id}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create batch: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(batchWizardProvider);
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';
    final productsAsync = ref.watch(productListProvider(businessId));
    final marketsAsync = ref.watch(marketListProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Batch'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(batchWizardProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: wizardState.currentStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => ref.read(batchWizardProvider.notifier).setStep(page),
              children: [
                _Step1ProductPurchase(productsAsync: productsAsync, marketsAsync: marketsAsync),
                _Step2Partners(),
                _Step3Packing(),
                _Step4Expenses(),
                _Step5Review(onConfirm: _createBatch),
              ],
            ),
          ),
          _BottomNavigation(
            currentStep: wizardState.currentStep,
            onBack: () {
              if (wizardState.currentStep > 0) {
                ref.read(batchWizardProvider.notifier).previousStep();
                _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
            onNext: () {
              if (wizardState.currentStep < 4) {
                ref.read(batchWizardProvider.notifier).nextStep();
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= currentStep ? Colors.green : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Step1ProductPurchase extends ConsumerWidget {
  final AsyncValue productsAsync;
  final AsyncValue marketsAsync;

  const _Step1ProductPurchase({required this.productsAsync, required this.marketsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 1: Product & Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          productsAsync.when(
            data: (products) => SearchableDropdown<ProductModel>(
              items: products as List<ProductModel>,
              itemLabel: (p) => '${p.name} (${p.category ?? 'No category'})',
              hintText: 'Search product...',
              createNewLabel: 'Create New Product',
              onChanged: (product) {
                if (product != null) ref.read(batchWizardProvider.notifier).updateProduct(product.id);
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 16),
          marketsAsync.when(
            data: (markets) => CityMarketDropdown(
              markets: markets as List<MarketModel>,
              label: 'Source Market',
              onCityChanged: (city) {},
              onMarketChanged: (marketId) {
                ref.read(batchWizardProvider.notifier).updateMarkets(marketId, null);
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 16),
          CityMarketDropdown(
            markets: marketsAsync.asData?.value ?? [],
            label: 'Destination Market',
            onCityChanged: (city) {},
            onMarketChanged: (marketId) {
              ref.read(batchWizardProvider.notifier).updateMarkets(
                ref.read(batchWizardProvider).sourceMarketId, marketId);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            onChanged: (v) => ref.read(batchWizardProvider.notifier).updatePurchaseDetails(
              quantity: double.tryParse(v),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Purchase Price Per Unit'),
            keyboardType: TextInputType.number,
            onChanged: (v) => ref.read(batchWizardProvider.notifier).updatePurchaseDetails(
              price: double.tryParse(v),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step2Partners extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 2: Purchasing Partners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Add partners who are involved in purchasing this batch.'),
          const SizedBox(height: 16),
          PartnerSelector(
            selectedPartners: const [],
            partnerDetails: const [],
            onChanged: (details) {},
            onAddPartner: () {},
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: 'purchaser',
            decoration: const InputDecoration(labelText: 'Transport Paid By'),
            items: const [
              DropdownMenuItem(value: 'purchaser', child: Text('Purchaser')),
              DropdownMenuItem(value: 'seller', child: Text('Seller')),
            ],
            onChanged: (v) => ref.read(batchWizardProvider.notifier).updatePurchaseDetails(
              transportPaidBy: v,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3Packing extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 3: Packing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          PackingEntryForm(
            records: const [],
            onChanged: (records) => ref.read(batchWizardProvider.notifier).updatePackingRecords(records),
          ),
        ],
      ),
    );
  }
}

class _Step4Expenses extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 4: Purchaser Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _ExpenseField(label: 'Labor Cost'),
          _ExpenseField(label: 'Accountant/Admin Cost'),
          _ExpenseField(label: 'Source Stall Fee'),
          _ExpenseField(label: 'Miscellaneous'),
        ],
      ),
    );
  }
}

class _ExpenseField extends StatelessWidget {
  final String label;
  const _ExpenseField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(labelText: '$label (PKR)'),
        keyboardType: TextInputType.number,
      ),
    );
  }
}

class _Step5Review extends StatelessWidget {
  final VoidCallback onConfirm;
  const _Step5Review({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 5: Review & Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          BatchSummaryCard(data: const {
            'product_name': 'Selected Product',
            'total_quantity': 0,
            'quantity_unit': 'kg',
            'purchase_price_per_unit': 0,
            'total_purchase_cost': 0,
            'total_packing_cost': 0,
            'transport_cost': 0,
            'estimated_total': 0,
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check),
              label: const Text('Confirm & Create Batch', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNavigation({
    required this.currentStep,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: onNext,
                child: Text(currentStep == 4 ? 'Review' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
