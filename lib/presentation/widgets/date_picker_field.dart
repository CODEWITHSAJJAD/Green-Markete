import 'package:flutter/material.dart';
import '../../core/utils/date_formatter.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      controller: TextEditingController(
        text: selectedDate != null ? DateFormatter.toDDMMYYYY(selectedDate!) : '',
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now(),
        );
        if (picked != null) onDateSelected(picked);
      },
    );
  }
}

class DatePickerFieldController extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerFieldController({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DatePickerFieldController> createState() => _DatePickerFieldControllerState();
}

class _DatePickerFieldControllerState extends State<DatePickerFieldController> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.selectedDate != null ? DateFormatter.toDDMMYYYY(widget.selectedDate!) : '',
    );
  }

  @override
  void didUpdateWidget(covariant DatePickerFieldController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _ctrl.text = widget.selectedDate != null ? DateFormatter.toDDMMYYYY(widget.selectedDate!) : '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: _ctrl,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: widget.selectedDate ?? DateTime.now(),
          firstDate: widget.firstDate ?? DateTime(2020),
          lastDate: widget.lastDate ?? DateTime.now(),
        );
        if (picked != null) widget.onDateSelected(picked);
      },
    );
  }
}