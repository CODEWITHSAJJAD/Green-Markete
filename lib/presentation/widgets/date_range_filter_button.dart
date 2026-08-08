import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../core/config/theme.dart';

class DateRangeFilterButton extends StatelessWidget {
  const DateRangeFilterButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
  });

  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;
  final DateTime? firstDate;

  @override
  Widget build(BuildContext context) {
    final hasRange = value != null;
    return Tooltip(
      message: hasRange
          ? '${value!.start.toString().split(' ').first} → ${value!.end.toString().split(' ').first}'
          : 'Filter by date range',
      child: IconButton(
        icon: Icon(
          hasRange ? MingCuteIcons.mgc_calendar_fill : MingCuteIcons.mgc_calendar_3_line,
          color: hasRange ? AppColors.primary : null,
        ),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: firstDate ?? DateTime(now.year - 2),
            lastDate: now,
            initialDateRange: value,
          );
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }
}