import 'package:flutter/material.dart';
import '../../../../data/models/partner_model.dart';
import '../../../widgets/partner_chip.dart';

class PartnerSelector extends StatelessWidget {
  final List<PartnerModel> selectedPartners;
  final List<Map<String, dynamic>> partnerDetails;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final VoidCallback onAddPartner;

  const PartnerSelector({
    super.key,
    required this.selectedPartners,
    required this.partnerDetails,
    required this.onChanged,
    required this.onAddPartner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Purchasing Partners', style: TextStyle(fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: onAddPartner,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Partner'),
            ),
          ],
        ),
        if (selectedPartners.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No partners added yet', style: TextStyle(color: Colors.grey)),
          )
        else
          ...selectedPartners.asMap().entries.map((entry) {
            final partner = entry.value;
            final index = entry.key;
            final details = partnerDetails.length > index ? partnerDetails[index] : <String, dynamic>{};
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: PartnerChip(name: partner.fullName, role: partner.role)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            final newList = List<PartnerModel>.from(selectedPartners)..removeAt(index);
                            final newDetails = List<Map<String, dynamic>>.from(partnerDetails)..removeAt(index);
                            onChanged(newDetails);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Daily Charge (PKR)',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final newDetails = List<Map<String, dynamic>>.from(partnerDetails);
                              newDetails[index] = {...details, 'daily_charge_rate': double.tryParse(v) ?? 0};
                              onChanged(newDetails);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Days',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final newDetails = List<Map<String, dynamic>>.from(partnerDetails);
                              newDetails[index] = {...details, 'days_involved': int.tryParse(v) ?? 1};
                              onChanged(newDetails);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
