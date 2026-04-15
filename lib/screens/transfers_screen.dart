import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_item.dart';
import '../services/transfer_provider.dart';
import '../widgets/transfer_card.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(transferProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        centerTitle: true,
        actions: [
          if (transfers.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(transferProvider.notifier).clearCompleted(),
              child: const Text('Clear Done'),
            ),
        ],
      ),
      body: transfers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 64, color: cs.outline),
                  const SizedBox(height: 12),
                  Text('No transfers yet', style: TextStyle(color: cs.outline)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transfers.length,
              itemBuilder: (ctx, i) => TransferCard(transfer: transfers[i]),
            ),
    );
  }
}
