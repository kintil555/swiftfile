import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/transfer_item.dart';

class TransferCard extends StatelessWidget {
  final TransferItem transfer;
  const TransferCard({super.key, required this.transfer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = transfer.status == TransferStatus.done;
    final isFailed = transfer.status == TransferStatus.failed;

    Color statusColor = cs.primary;
    if (isDone) statusColor = Colors.green;
    if (isFailed) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  transfer.type == TransferType.send ? Icons.upload : Icons.download,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transfer.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: transfer.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(_modeIcon(transfer.mode), size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(transfer.sizeLabel, style: Theme.of(context).textTheme.bodySmall),
                if (transfer.peerName != null) ...[
                  const SizedBox(width: 8),
                  Text('• ${transfer.peerName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
                ],
              ],
            ),
            if (transfer.status == TransferStatus.transferring ||
                transfer.status == TransferStatus.connecting) ...[
              const SizedBox(height: 10),
              LinearPercentIndicator(
                lineHeight: 6,
                percent: transfer.progress.clamp(0.0, 1.0),
                progressColor: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
                barRadius: const Radius.circular(3),
                padding: EdgeInsets.zero,
                trailing: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('${(transfer.progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(TransferMode mode) {
    switch (mode) {
      case TransferMode.wifi:
        return Icons.wifi;
      case TransferMode.bluetooth:
        return Icons.bluetooth;
      case TransferMode.usb:
        return Icons.usb;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final TransferStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (status) {
      case TransferStatus.pending:
        label = 'Pending';
        color = Colors.grey;
        break;
      case TransferStatus.connecting:
        label = 'Connecting';
        color = Colors.orange;
        break;
      case TransferStatus.transferring:
        label = 'Sending';
        color = Colors.blue;
        break;
      case TransferStatus.done:
        label = 'Done';
        color = Colors.green;
        break;
      case TransferStatus.failed:
        label = 'Failed';
        color = Colors.red;
        break;
      case TransferStatus.paused:
        label = 'Paused';
        color = Colors.amber;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
