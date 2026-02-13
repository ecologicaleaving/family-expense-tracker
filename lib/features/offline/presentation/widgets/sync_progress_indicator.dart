import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/offline_providers.dart';

/// T082: Sync progress indicator for batch sync operations
///
/// Shows:
/// - Current sync progress (X of Y)
/// - Progress bar
/// - Completion status
class SyncProgressIndicator extends ConsumerWidget {
  const SyncProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    if (!syncState.isSyncing && syncState.lastResult == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (syncState.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    syncState.lastResult!.allSuccess
                        ? Icons.check_circle
                        : Icons.warning,
                    color: syncState.lastResult!.allSuccess
                        ? Colors.green
                        : Colors.orange,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    syncState.isSyncing
                        ? 'Sincronizzazione in corso...'
                        : syncState.lastResult!.allSuccess
                            ? 'Sincronizzazione completata'
                            : 'Sincronizzazione parziale',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (syncState.lastResult != null) ...[
              const SizedBox(height: 12),
              _buildResultSummary(syncState.lastResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary(SyncResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (result.successful > 0)
          _buildResultRow(
            Icons.check_circle_outline,
            Colors.green,
            '${result.successful} sincronizzate',
          ),
        if (result.failed > 0)
          _buildResultRow(
            Icons.error_outline,
            Colors.red,
            '${result.failed} non riuscite',
          ),
        if (result.conflicts > 0)
          _buildResultRow(
            Icons.warning_amber_outlined,
            Colors.orange,
            '${result.conflicts} conflitti',
          ),
      ],
    );
  }

  Widget _buildResultRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync state for progress tracking
class SyncState {
  final bool isSyncing;
  final SyncResult? lastResult;

  const SyncState({
    this.isSyncing = false,
    this.lastResult,
  });

  SyncState copyWith({
    bool? isSyncing,
    SyncResult? lastResult,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// Sync result summary
class SyncResult {
  final int processed;
  final int successful;
  final int failed;
  final int conflicts;

  const SyncResult({
    required this.processed,
    required this.successful,
    required this.failed,
    required this.conflicts,
  });

  bool get allSuccess =>
      processed == successful && failed == 0 && conflicts == 0;
  bool get hasFailures => failed > 0;
  bool get hasConflicts => conflicts > 0;
}
