import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/offline/presentation/providers/offline_providers.dart';
import '../services/connectivity_service.dart';

/// T081: Offline banner showing network status and pending sync count
/// T024: Extended to support stale data mode (Feature 012-expense-improvements US2)
///
/// Displays when:
/// - Device is offline
/// - There are pending expenses to sync
/// - Data might be stale (online but last sync >5 minutes ago)
///
/// Features:
/// - Network status indicator
/// - Pending expense count
/// - Manual retry button
/// - Stale data warning
/// - Dismissible
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({
    super.key,
    this.showStaleDataWarning = false,
  });

  /// Whether to show stale data warning when online but data is old
  final bool showStaleDataWarning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connectivity status
    final connectivityStatus = ref.watch(connectivityServiceProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final lastSyncTimeAsync = ref.watch(lastSyncTimeProvider);

    return connectivityStatus.when(
      data: (status) {
        // Check for various states
        final isOffline = status == NetworkStatus.offline;
        final pendingCount = pendingCountAsync.valueOrNull ?? 0;
        final hasPending = pendingCount > 0;

        // T024: Check if data is stale (online but last sync >5 minutes ago)
        final now = DateTime.now();
        final lastSync = lastSyncTimeAsync.valueOrNull;
        final isStale = showStaleDataWarning &&
            !isOffline &&
            lastSync != null &&
            now.difference(lastSync).inMinutes > 5;

        // Only show banner if offline, has pending items, or data is stale
        if (!isOffline && !hasPending && !isStale) {
          return const SizedBox.shrink();
        }

        // Determine banner color and icon based on state
        final Color bannerColor;
        final IconData icon;
        final String title;

        if (isOffline) {
          bannerColor = Colors.orange.shade700;
          icon = Icons.cloud_off;
          title = 'Modalità offline';
        } else if (isStale) {
          bannerColor = Colors.amber.shade700;
          icon = Icons.warning_amber_rounded;
          title = 'Dati potrebbero essere obsoleti';
        } else {
          bannerColor = Colors.blue.shade700;
          icon = Icons.cloud_queue;
          title = 'Sincronizzazione in corso';
        }

        return Material(
          color: bannerColor,
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasPending) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$pendingCount ${pendingCount == 1 ? "spesa" : "spese"} da sincronizzare',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // T084: Manual retry button
                if (!isOffline && hasPending) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(syncTriggerProvider.notifier).manualSync();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Riprova',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
