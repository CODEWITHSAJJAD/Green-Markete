import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../core/config/theme.dart';
import '../providers/connectivity_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isOnline ? 0 : 38,
      color: AppColors.error.withValues(alpha: 0.10),
      child: isOnline
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MingCuteIcons.mgc_wifi_off_line, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'You are offline. Showing cached data where possible.',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ],
              ),
            ),
    );
  }
}