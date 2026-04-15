import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/transfer_item.dart';
import '../services/transfer_provider.dart';
import '../services/wifi_transfer_service.dart';
import '../widgets/transfer_card.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  bool _listening = false;
  String? _localIp;

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final ip = await NetworkInfo().getWifiIP();
    if (mounted) setState(() => _localIp = ip);
  }

  Future<void> _toggleListen() async {
    final wifiSvc = ref.read(wifiServiceProvider);
    final transfers = ref.read(transferProvider.notifier);

    if (_listening) {
      await wifiSvc.stopServer();
      setState(() => _listening = false);
      return;
    }

    await wifiSvc.startServer(
      onIncomingRequest: (fileId, fileName, size, senderIp) {
        transfers.addTransfer(
          fileName: fileName,
          totalBytes: size,
          type: TransferType.receive,
          mode: TransferMode.wifi,
          peerName: senderIp,
        );
      },
      onProgress: (fileId, received, total) {
        // Update by fileName match since we don't have the exact id here
        // In real impl you'd track fileId -> transfer id map
      },
      onDone: (fileId, savedPath) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: $savedPath'), backgroundColor: Colors.green),
        );
      },
    );

    setState(() => _listening = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allTransfers = ref.watch(transferProvider)
        .where((t) => t.type == TransferType.receive)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Receive Files'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _listening
                      ? [const Color(0xFF43C6AC), const Color(0xFF191654)]
                      : [cs.surfaceContainerHighest, cs.surfaceContainerHighest],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _listening ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                      key: ValueKey(_listening),
                      size: 56,
                      color: _listening ? Colors.white : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _listening ? 'Listening for files...' : 'Tap to start receiving',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _listening ? Colors.white : cs.onSurface,
                    ),
                  ),
                  if (_localIp != null && _listening) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tell sender: $_localIp',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Port: $kServerPort',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: _listening
                  ? OutlinedButton.icon(
                      onPressed: _toggleListen,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Receiving'),
                    )
                  : FilledButton.icon(
                      onPressed: _toggleListen,
                      icon: const Icon(Icons.download),
                      label: const Text('Start Receiving'),
                    ),
            ),

            const SizedBox(height: 24),

            if (allTransfers.isNotEmpty) ...[
              Row(
                children: [
                  Text('Received Files', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref.read(transferProvider.notifier).clearCompleted(),
                    child: const Text('Clear done'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: allTransfers.length,
                  itemBuilder: (ctx, i) => TransferCard(transfer: allTransfers[i]),
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: cs.outline),
                      const SizedBox(height: 12),
                      Text('No files received yet', style: TextStyle(color: cs.outline)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_listening) ref.read(wifiServiceProvider).stopServer();
    super.dispose();
  }
}
