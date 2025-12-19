import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/invite_code_generator.dart';
import '../../domain/entities/invite_entity.dart';

/// Card displaying an invite code with copy and share functionality.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.invite,
    this.onRefresh,
  });

  final InviteEntity invite;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedCode = InviteCodeGenerator.formatForDisplay(invite.code);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Code display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    formattedCode,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scade ${DateFormatter.formatRelativeWithDate(invite.expiresAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCode(context),
                    icon: const Icon(Icons.copy, size: 20),
                    label: const Text('Copia'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareCode(context),
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Condividi'),
                  ),
                ),
              ],
            ),

            // Refresh button
            if (onRefresh != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Genera nuovo codice'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invite.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Codice copiato negli appunti'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode(BuildContext context) {
    // For now, just copy. In a full app, you'd use share_plus package
    final message = 'Unisciti al mio gruppo famiglia su Spese di Casa! '
        'Usa il codice: ${invite.code}';

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaggio copiato negli appunti'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Compact invite code display for inline use.
class InviteCodeChip extends StatelessWidget {
  const InviteCodeChip({
    super.key,
    required this.code,
    this.onTap,
  });

  final String code;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedCode = InviteCodeGenerator.formatForDisplay(code);

    return InkWell(
      onTap: onTap ?? () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Codice copiato'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedCode,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.copy,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
