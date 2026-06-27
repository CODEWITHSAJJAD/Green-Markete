import 'package:flutter/material.dart';
import '../../../widgets/status_pill.dart';

class StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const StatusTimeline({super.key, required this.currentStatus});

  static const _statuses = ['purchased', 'packed', 'in_transit', 'delivered', 'selling', 'closed'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _statuses.indexOf(currentStatus.toLowerCase());
    return Row(
      children: List.generate(_statuses.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: isCurrent ? 28 : 20,
                height: isCurrent ? 28 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                ),
                child: isCurrent
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                _statusLabel(_statuses[index]),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (index < _statuses.length - 1)
                Container(
                  height: 2,
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                ),
            ],
          ),
        );
      }),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_transit': return 'In\nTransit';
      default: return status[0].toUpperCase() + status.substring(1);
    }
  }
}
