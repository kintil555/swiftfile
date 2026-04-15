import 'package:flutter/foundation.dart';

enum TransferStatus { pending, connecting, transferring, done, failed, paused }
enum TransferType { send, receive }
enum TransferMode { wifi, bluetooth, usb }

@immutable
class TransferItem {
  final String id;
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final TransferStatus status;
  final TransferType type;
  final TransferMode mode;
  final String? peerName;
  final String? filePath;
  final DateTime startedAt;

  const TransferItem({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.status = TransferStatus.pending,
    required this.type,
    required this.mode,
    this.peerName,
    this.filePath,
    required this.startedAt,
  });

  double get progress =>
      totalBytes > 0 ? transferredBytes / totalBytes : 0.0;

  String get speedLabel {
    if (status != TransferStatus.transferring) return '';
    return '${(transferredBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String get sizeLabel {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(totalBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  TransferItem copyWith({
    int? transferredBytes,
    TransferStatus? status,
    String? filePath,
  }) {
    return TransferItem(
      id: id,
      fileName: fileName,
      totalBytes: totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      status: status ?? this.status,
      type: type,
      mode: mode,
      peerName: peerName,
      filePath: filePath ?? this.filePath,
      startedAt: startedAt,
    );
  }
}
