import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../models/transfer_item.dart';

const int kServerPort = 54321;

class WifiTransferService {
  HttpServer? _server;
  final _networkInfo = NetworkInfo();
  final _dio = Dio();

  // Files being served: id -> file path
  final Map<String, String> _servedFiles = {};

  Future<String?> getLocalIp() => _networkInfo.getWifiIP();

  /// Start HTTP server to serve files
  Future<void> startServer({
    required void Function(String fileId, String fileName, int size, String senderIp) onIncomingRequest,
    required void Function(String fileId, int received, int total) onProgress,
    required void Function(String fileId, String savedPath) onDone,
  }) async {
    final router = Router();

    // List available files
    router.get('/files', (shelf.Request req) {
      final list = _servedFiles.entries.map((e) {
        final f = File(e.value);
        return '{"id":"${e.key}","name":"${f.uri.pathSegments.last}","size":${f.lengthSync()}}';
      }).join(',');
      return shelf.Response.ok('[$list]', headers: {'Content-Type': 'application/json'});
    });

    // Download a file - supports Range header for resume
    router.get('/file/<id>', (shelf.Request req, String id) async {
      final path = _servedFiles[id];
      if (path == null) return shelf.Response.notFound('File not found');
      final file = File(path);
      if (!file.existsSync()) return shelf.Response.notFound('File gone');

      final size = file.lengthSync();
      final rangeHeader = req.headers['range'];
      int start = 0;
      int end = size - 1;

      if (rangeHeader != null) {
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
        if (match != null) {
          start = int.parse(match.group(1)!);
          if (match.group(2)!.isNotEmpty) end = int.parse(match.group(2)!);
        }
      }

      final length = end - start + 1;
      final stream = file.openRead(start, end + 1);

      return shelf.Response(
        rangeHeader != null ? 206 : 200,
        body: stream,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': '$length',
          'Content-Disposition': 'attachment; filename="${file.uri.pathSegments.last}"',
          'Accept-Ranges': 'bytes',
          if (rangeHeader != null) 'Content-Range': 'bytes $start-$end/$size',
        },
      );
    });

    // Upload endpoint (push mode)
    router.post('/upload', (shelf.Request req) async {
      final fileName = req.headers['x-file-name'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
      final totalSize = int.tryParse(req.headers['content-length'] ?? '0') ?? 0;
      final fileId = const Uuid().v4();
      final senderIp = req.headers['x-forwarded-for'] ?? 'unknown';

      final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final savePath = '${dir.path}/$fileName';
      final outFile = File(savePath).openWrite();

      onIncomingRequest(fileId, fileName, totalSize, senderIp);

      int received = 0;
      await for (final chunk in req.read()) {
        outFile.add(chunk);
        received += chunk.length;
        onProgress(fileId, received, totalSize);
      }
      await outFile.close();
      onDone(fileId, savePath);

      return shelf.Response.ok('{"id":"$fileId","path":"$savePath"}',
          headers: {'Content-Type': 'application/json'});
    });

    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, kServerPort);
  }

  /// Add file to be served (pull mode)
  String serveFile(String filePath) {
    final id = const Uuid().v4();
    _servedFiles[id] = filePath;
    return id;
  }

  void unserveFile(String id) => _servedFiles.remove(id);

  /// Download file from peer with IDM-style chunked parallel download
  Future<void> downloadFile({
    required String peerIp,
    required String fileId,
    required String fileName,
    required int totalSize,
    required void Function(int received, int total) onProgress,
    required void Function(String path) onDone,
    required void Function(String err) onError,
  }) async {
    try {
      final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final savePath = '${dir.path}/$fileName';

      const int chunks = 4;
      final chunkSize = totalSize ~/ chunks;
      final tempFiles = <String>[];
      final futures = <Future>[];
      int totalReceived = 0;

      for (int i = 0; i < chunks; i++) {
        final start = i * chunkSize;
        final end = (i == chunks - 1) ? totalSize - 1 : (start + chunkSize - 1);
        final tempPath = '${dir.path}/$fileId.part$i';
        tempFiles.add(tempPath);

        futures.add(
          _dio.download(
            'http://$peerIp:$kServerPort/file/$fileId',
            tempPath,
            options: Options(headers: {'Range': 'bytes=$start-$end'}),
            onReceiveProgress: (received, _) {
              totalReceived += received;
              onProgress(totalReceived.clamp(0, totalSize), totalSize);
            },
          ),
        );
      }

      await Future.wait(futures);

      // Merge chunks
      final outFile = File(savePath).openWrite();
      for (final part in tempFiles) {
        final f = File(part);
        await outFile.addStream(f.openRead());
        await f.delete();
      }
      await outFile.close();
      onDone(savePath);
    } on DioException catch (e) {
      onError(e.message ?? 'Download failed');
    }
  }

  /// Send file to peer (push mode)
  Future<void> sendFileTo({
    required String peerIp,
    required String filePath,
    required void Function(int sent, int total) onProgress,
    required void Function() onDone,
    required void Function(String err) onError,
  }) async {
    try {
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;
      final size = file.lengthSync();

      await _dio.post(
        'http://$peerIp:$kServerPort/upload',
        data: file.openRead(),
        options: Options(headers: {
          'x-file-name': fileName,
          'Content-Length': '$size',
          'Content-Type': 'application/octet-stream',
        }),
        onSendProgress: (sent, total) => onProgress(sent, total),
      );
      onDone();
    } on DioException catch (e) {
      onError(e.message ?? 'Send failed');
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  void dispose() {
    stopServer();
    _dio.close(force: true);
  }
}

// Riverpod provider
final wifiServiceProvider = Provider((ref) {
  final svc = WifiTransferService();
  ref.onDispose(svc.dispose);
  return svc;
});
