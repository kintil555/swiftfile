import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transfer_item.dart';

class TransferNotifier extends StateNotifier<List<TransferItem>> {
  TransferNotifier() : super([]);

  final _uuid = const Uuid();

  String addTransfer({
    required String fileName,
    required int totalBytes,
    required TransferType type,
    required TransferMode mode,
    String? peerName,
  }) {
    final id = _uuid.v4();
    state = [
      TransferItem(
        id: id,
        fileName: fileName,
        totalBytes: totalBytes,
        type: type,
        mode: mode,
        peerName: peerName,
        startedAt: DateTime.now(),
      ),
      ...state,
    ];
    return id;
  }

  void updateProgress(String id, int transferred) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(
            transferredBytes: transferred,
            status: TransferStatus.transferring,
          )
        else
          t
    ];
  }

  void setStatus(String id, TransferStatus status, {String? filePath}) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: status, filePath: filePath) else t
    ];
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void clearCompleted() {
    state = state
        .where((t) =>
            t.status != TransferStatus.done &&
            t.status != TransferStatus.failed)
        .toList();
  }
}

final transferProvider =
    StateNotifierProvider<TransferNotifier, List<TransferItem>>(
  (ref) => TransferNotifier(),
);

final activeTransfersProvider = Provider<List<TransferItem>>((ref) {
  return ref
      .watch(transferProvider)
      .where((t) =>
          t.status == TransferStatus.transferring ||
          t.status == TransferStatus.connecting ||
          t.status == TransferStatus.pending)
      .toList();
});
