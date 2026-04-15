import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/transfer_item.dart';
import '../services/transfer_provider.dart';
import '../services/wifi_transfer_service.dart';
import '../widgets/transfer_card.dart';

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _ipController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  bool _isSending = false;
  String? _localIp;
  TransferMode _mode = TransferMode.wifi;

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final ip = await NetworkInfo().getWifiIP();
    if (mounted) setState(() => _localIp = ip);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) setState(() => _selectedFiles = result.files);
  }

  Future<void> _send() async {
    if (_selectedFiles.isEmpty || _ipController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    final wifiSvc = ref.read(wifiServiceProvider);
    final transfers = ref.read(transferProvider.notifier);
    final peerIp = _ipController.text.trim();

    for (final file in _selectedFiles) {
      if (file.path == null) continue;
      final id = transfers.addTransfer(
        fileName: file.name,
        totalBytes: file.size,
        type: TransferType.send,
        mode: _mode,
        peerName: peerIp,
      );
      transfers.setStatus(id, TransferStatus.connecting);

      await wifiSvc.sendFileTo(
        peerIp: peerIp,
        filePath: file.path!,
        onProgress: (sent, total) => transfers.updateProgress(id, sent),
        onDone: () => transfers.setStatus(id, TransferStatus.done),
        onError: (e) {
          transfers.setStatus(id, TransferStatus.failed);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        },
      );
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = ref.watch(activeTransfersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Send Files'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My IP
            if (_localIp != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.computer, color: cs.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your IP (share with receiver)'),
                        Text(_localIp!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                                fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Transfer mode
            Text('Transfer Mode', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<TransferMode>(
              segments: const [
                ButtonSegment(value: TransferMode.wifi, icon: Icon(Icons.wifi), label: Text('WiFi')),
                ButtonSegment(value: TransferMode.bluetooth, icon: Icon(Icons.bluetooth), label: Text('BT')),
                ButtonSegment(value: TransferMode.usb, icon: Icon(Icons.usb), label: Text('USB')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),

            const SizedBox(height: 20),

            // Peer IP
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Receiver IP Address',
                hintText: '192.168.x.x',
                prefixIcon: const Icon(Icons.lan),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 20),

            // File selection
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainerHighest,
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 48, color: cs.primary),
                    const SizedBox(height: 8),
                    Text(_selectedFiles.isEmpty
                        ? 'Tap to select files'
                        : '${_selectedFiles.length} file(s) selected'),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._selectedFiles.take(3).map((f) => Text(
                            '• ${f.name} (${_formatSize(f.size)})',
                            style: Theme.of(context).textTheme.bodySmall,
                          )),
                      if (_selectedFiles.length > 3)
                        Text('...and ${_selectedFiles.length - 3} more',
                            style: Theme.of(context).textTheme.bodySmall),
                    ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: (_isSending || _selectedFiles.isEmpty) ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Sending...' : 'Send Now'),
              ),
            ),

            if (active.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Active Transfers', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...active.map((t) => TransferCard(transfer: t)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
