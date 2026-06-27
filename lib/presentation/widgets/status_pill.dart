import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'purchased':
        return Colors.grey;
      case 'packed':
        return Colors.blue;
      case 'in_transit':
        return Colors.amber.shade700;
      case 'delivered':
        return Colors.green;
      case 'selling':
        return Colors.teal;
      case 'closed':
        return Colors.grey.shade800;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'in_transit':
        return 'In Transit';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
